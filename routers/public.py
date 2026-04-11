import json

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Answer, Response, Survey
from schemas import ResponseCreate

router = APIRouter()


@router.get("/encuesta/{slug}")
def get_survey(slug: str, db: Session = Depends(get_db)):
    survey = (
        db.query(Survey)
        .filter(Survey.slug == slug, Survey.is_active.is_(True))
        .first()
    )
    if not survey:
        raise HTTPException(status_code=404, detail="Encuesta no encontrada o no disponible")

    return {
        "id": survey.id,
        "slug": survey.slug,
        "title": survey.title,
        "description": survey.description,
        "questions": [
            {
                "id": q.id,
                "type": q.type,
                "label": q.label,
                "options": q.options,
                "required": q.required,
                "order": q.order,
            }
            for q in survey.questions
        ],
    }


@router.post("/encuesta/{slug}/responder", status_code=201)
def submit_response(slug: str, data: ResponseCreate, db: Session = Depends(get_db)):
    survey = (
        db.query(Survey)
        .filter(Survey.slug == slug, Survey.is_active.is_(True))
        .first()
    )
    if not survey:
        raise HTTPException(status_code=404, detail="Encuesta no encontrada o no disponible")

    required_ids = {q.id for q in survey.questions if q.required}
    answered_ids = {
        a.question_id for a in data.answers
        if a.value and a.value.strip() not in ("", "[]")
    }
    missing = required_ids - answered_ids
    if missing:
        raise HTTPException(status_code=422, detail="Faltan respuestas obligatorias")

    valid_ids = {q.id for q in survey.questions}
    response = Response(survey_id=survey.id)
    db.add(response)
    db.flush()

    for ans in data.answers:
        if ans.question_id not in valid_ids:
            continue
        db.add(Answer(
            response_id=response.id,
            question_id=ans.question_id,
            value=ans.value,
        ))

    db.commit()
    return {"ok": True, "response_id": response.id}
