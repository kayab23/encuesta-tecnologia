import asyncio
import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from database import engine
from routers import admin, public

BASE_DIR = Path(__file__).resolve().parent
logger = logging.getLogger("keepalive")

PING_INTERVAL = 10 * 60  # 10 minutos


async def _keepalive():
    """Pinga el propio /health cada 10 min para evitar el reposo en Render."""
    base_url = os.getenv("RENDER_EXTERNAL_URL", "").rstrip("/")
    if not base_url:
        logger.info("RENDER_EXTERNAL_URL no definida — keep-alive desactivado (entorno local)")
        return
    url = f"{base_url}/health"
    async with httpx.AsyncClient(timeout=10) as client:
        while True:
            await asyncio.sleep(PING_INTERVAL)
            try:
                r = await client.get(url)
                logger.info("keep-alive ping → %s %s", url, r.status_code)
            except Exception as exc:
                logger.warning("keep-alive error: %s", exc)


@asynccontextmanager
async def lifespan(app: FastAPI):
    from database import Base
    Base.metadata.create_all(bind=engine)
    task = asyncio.create_task(_keepalive())
    yield
    task.cancel()


app = FastAPI(title="Plataforma de Encuestas", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# API routes — deben registrarse ANTES del mount estático
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])
app.include_router(public.router, prefix="/api", tags=["Público"])


@app.get("/health", tags=["Sistema"])
def health():
    return {"status": "ok"}

# Sirve el frontend como archivos estáticos
app.mount("/", StaticFiles(directory=str(BASE_DIR / "frontend"), html=True), name="frontend")
