import csv
import io
import json
import os
from collections import Counter
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Header
from fastapi.responses import StreamingResponse
import re
import unicodedata
from sqlalchemy.orm import Session

from database import get_db
from models import Answer, Question, Response, Survey
from schemas import SurveyCreate, SurveyOut

router = APIRouter()


def _slugify(text: str) -> str:
    """Genera un slug URL-seguro a partir de texto."""
    text = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode('ascii')
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    text = re.sub(r'^-+|-+$', '', text)
    return text or 'encuesta'


def verify_admin(x_admin_key: Annotated[str | None, Header()] = None):
    expected = os.getenv("ADMIN_KEY", "admin123")
    if x_admin_key != expected:
        raise HTTPException(status_code=401, detail="Clave de administrador inválida")


# ─── Crear encuesta ───────────────────────────────────────────────────────────

@router.post("/surveys", response_model=SurveyOut, dependencies=[Depends(verify_admin)])
def create_survey(data: SurveyCreate, db: Session = Depends(get_db)):
    base_slug = _slugify(data.title)
    slug, i = base_slug, 2
    while db.query(Survey).filter(Survey.slug == slug).first():
        slug = f"{base_slug}-{i}"
        i += 1

    survey = Survey(slug=slug, title=data.title, description=data.description)
    db.add(survey)
    db.flush()

    for q in data.questions:
        db.add(Question(
            survey_id=survey.id,
            type=q.type,
            label=q.label,
            options=q.options,
            required=q.required,
            order=q.order,
        ))

    db.commit()
    db.refresh(survey)
    return survey


# ─── Listar encuestas ─────────────────────────────────────────────────────────

@router.get("/surveys", dependencies=[Depends(verify_admin)])
def list_surveys(db: Session = Depends(get_db)):
    surveys = db.query(Survey).order_by(Survey.created_at.desc()).all()
    return [
        {
            "id": s.id,
            "slug": s.slug,
            "title": s.title,
            "is_active": s.is_active,
            "created_at": s.created_at,
            "response_count": db.query(Response).filter(Response.survey_id == s.id).count(),
        }
        for s in surveys
    ]


# ─── Activar / Desactivar ─────────────────────────────────────────────────────

@router.patch("/surveys/{slug}/toggle", dependencies=[Depends(verify_admin)])
def toggle_survey(slug: str, db: Session = Depends(get_db)):
    survey = db.query(Survey).filter(Survey.slug == slug).first()
    if not survey:
        raise HTTPException(status_code=404, detail="Encuesta no encontrada")
    survey.is_active = not survey.is_active
    db.commit()
    return {"slug": survey.slug, "is_active": survey.is_active}


# ─── Eliminar encuesta ────────────────────────────────────────────────────────

@router.delete("/surveys/{slug}", dependencies=[Depends(verify_admin)])
def delete_survey(slug: str, db: Session = Depends(get_db)):
    survey = db.query(Survey).filter(Survey.slug == slug).first()
    if not survey:
        raise HTTPException(status_code=404, detail="Encuesta no encontrada")
    db.delete(survey)
    db.commit()
    return {"deleted": True}


# ─── Resultados ───────────────────────────────────────────────────────────────

@router.get("/surveys/{slug}/results", dependencies=[Depends(verify_admin)])
def get_results(slug: str, db: Session = Depends(get_db)):
    survey = db.query(Survey).filter(Survey.slug == slug).first()
    if not survey:
        raise HTTPException(status_code=404, detail="Encuesta no encontrada")

    total = db.query(Response).filter(Response.survey_id == survey.id).count()
    questions_data = []

    for q in survey.questions:
        answers = db.query(Answer).filter(Answer.question_id == q.id).all()
        raw_values: list[str] = []

        for a in answers:
            if not a.value:
                continue
            try:
                parsed = json.loads(a.value)
                if isinstance(parsed, list):
                    raw_values.extend(str(v) for v in parsed)
                else:
                    raw_values.append(str(parsed))
            except (json.JSONDecodeError, ValueError):
                raw_values.append(a.value)

        if q.type in ("radio", "select", "checkbox", "scale"):
            summary = dict(Counter(raw_values))
        else:
            summary = {"total_respuestas": len(raw_values)}

        questions_data.append({
            "id": q.id,
            "label": q.label,
            "type": q.type,
            "options": q.options,
            "summary": summary,
            "raw_values": raw_values,
        })

    return {
        "slug": survey.slug,
        "title": survey.title,
        "total_responses": total,
        "questions": questions_data,
    }


# ─── Exportar CSV ─────────────────────────────────────────────────────────────

@router.get("/surveys/{slug}/export", dependencies=[Depends(verify_admin)])
def export_csv(slug: str, db: Session = Depends(get_db)):
    survey = db.query(Survey).filter(Survey.slug == slug).first()
    if not survey:
        raise HTTPException(status_code=404, detail="Encuesta no encontrada")

    responses = db.query(Response).filter(Response.survey_id == survey.id).all()
    questions = survey.questions

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id_respuesta", "fecha"] + [q.label for q in questions])

    for resp in responses:
        answers_map = {a.question_id: a.value for a in resp.answers}
        row = [resp.id, resp.submitted_at.strftime("%Y-%m-%d %H:%M")]
        for q in questions:
            val = answers_map.get(q.id, "")
            if val:
                try:
                    parsed = json.loads(val)
                    if isinstance(parsed, list):
                        val = ", ".join(parsed)
                except (json.JSONDecodeError, ValueError):
                    pass
            row.append(val)
        writer.writerow(row)

    output.seek(0)
    filename = f"resultados_{slug}_{datetime.now().strftime('%Y%m%d')}.csv"
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )
