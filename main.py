from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from database import engine
from routers import admin, public

BASE_DIR = Path(__file__).resolve().parent


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Las migraciones se ejecutan con `alembic upgrade head` antes del arranque.
    # En desarrollo local también se pueden crear tablas si no existen.
    from database import Base
    Base.metadata.create_all(bind=engine)
    yield


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

# Sirve el frontend como archivos estáticos
app.mount("/", StaticFiles(directory=str(BASE_DIR / "frontend"), html=True), name="frontend")
