# Plataforma de Encuestas Internas

Sistema completo para crear, publicar y analizar encuestas de diagnóstico interno. Desarrollado con **FastAPI** (Python) en el backend y **HTML + JS puro** en el frontend, sin dependencias de frameworks externos.

**Producción:** https://encuesta-tecnologia.onrender.com  
**ADMIN_KEY:** `EncuestasIT01`

---

## ¿Qué incluye?

| Módulo | Descripción |
|--------|-------------|
| **Panel Admin** | Crear encuestas, ver lista, activar/pausar, eliminar |
| **Constructor de encuestas** | Drag de preguntas con 6 tipos distintos |
| **Página pública** | URL compartible con cualquier persona |
| **Dashboard de resultados** | Gráficas por pregunta + tabla de frecuencias |
| **Exportación CSV** | Descarga de todas las respuestas |
| **Manual de uso** | `/admin/manual.html` — guía completa integrada |

---

## Tipos de pregunta soportados

- **radio** — Opción única
- **checkbox** — Opción múltiple
- **select** — Lista desplegable
- **scale** — Escala numérica configurable (ej. 1–5)
- **text** — Texto corto
- **textarea** — Texto largo / párrafo

---

## Estructura del proyecto

```
Encuestas_Platform/
├── main.py               # FastAPI app + lifespan + keep-alive + /health
├── database.py           # Conexión SQLAlchemy (SQLite dev / PostgreSQL prod)
├── models.py             # Modelos: Survey, Question, Response, Answer
├── schemas.py            # Validación Pydantic
├── routers/
│   ├── admin.py          # CRUD encuestas, resultados, exportar CSV
│   └── public.py         # Ver encuesta + enviar respuesta
├── alembic/              # Migraciones de base de datos
│   └── versions/         # a2474eac22a0_initial_schema.py
├── frontend/
│   ├── index.html        # Redirige a /admin/
│   ├── encuesta.html     # Página pública (link que se comparte)
│   └── admin/
│       ├── index.html    # Panel: lista encuestas + login con toggle de ojo
│       ├── crear.html    # Constructor de encuesta
│       ├── resultados.html # Dashboard con gráficas Chart.js
│       └── manual.html   # Manual completo de uso (9 secciones)
├── render.yaml           # Configuración Render (sin DB propia - usar Neon)
├── requirements.txt
├── .env                  # Variables locales (no commitear)
├── crear_encuesta_tecnologia.ps1  # Script PS para restaurar encuesta
└── start.bat             # Script de arranque para Windows
```

---

## Instalación y arranque local

### Requisitos
- Python 3.10+

### Pasos

**1. Configurar variables de entorno**
```bash
copy .env.example .env
```
Edita `.env`:
```env
DATABASE_URL=postgresql://neondb_owner:password@ep-xxx.neon.tech/neondb?sslmode=require
ADMIN_KEY=anuar2309
```

**2. Instalar dependencias**
```bash
pip install -r requirements.txt
```

**3. Aplicar migraciones**
```bash
alembic upgrade head
```

**4. Arrancar el servidor**
```bash
uvicorn main:app --port 8000
```

**5. Acceder**

| URL | Descripción |
|-----|-------------|
| `http://localhost:8000/admin/` | Panel de administración |
| `http://localhost:8000/encuesta.html?s=SLUG` | Encuesta pública |
| `http://localhost:8000/admin/manual.html` | Manual de uso |

---

## Variables de entorno

```env
DATABASE_URL=postgresql://usuario:password@host/dbname?sslmode=require
ADMIN_KEY=tu_clave_segura
RENDER_EXTERNAL_URL=https://tu-servicio.onrender.com  # Solo en Render (auto)
```

> Para desarrollo local con SQLite: `DATABASE_URL=sqlite:///./encuestas.db`

---

## Despliegue en Render + Neon

1. Crear BD gratuita en [neon.tech](https://neon.tech) → copiar connection string
2. En Render Dashboard → servicio → **Environment** → agregar `DATABASE_URL`
3. El `buildCommand` en `render.yaml` ejecuta `alembic upgrade head` automáticamente
4. Restaurar encuesta de tecnología: `.\crear_encuesta_tecnologia.ps1`

> **Keep-alive:** La app hace ping a `/health` cada 10 min para evitar el reposo en Render free tier.

---

## Flujo de uso

```
Admin crea encuesta → Obtiene URL → Comparte por correo/WhatsApp
       ↓
Destinatario responde en el navegador (sin login)
       ↓
Respuestas guardadas en la base de datos
       ↓
Admin ve dashboard con gráficas + exporta CSV
```

---

## API REST

### Público (sin autenticación)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/encuesta/{slug}` | Obtener datos de la encuesta |
| POST | `/api/encuesta/{slug}/responder` | Enviar respuesta |
| GET | `/health` | Estado del servicio + tipo de BD |

### Admin (requiere header `X-Admin-Key`)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/admin/surveys` | Listar encuestas |
| POST | `/api/admin/surveys` | Crear encuesta |
| PATCH | `/api/admin/surveys/{slug}/toggle` | Activar/pausar |
| DELETE | `/api/admin/surveys/{slug}` | Eliminar |
| GET | `/api/admin/surveys/{slug}/results` | Resultados con conteos |
| GET | `/api/admin/surveys/{slug}/export` | Exportar CSV |

---

## Tecnologías

- **Backend:** FastAPI 0.115, SQLAlchemy 2.0, Alembic 1.14, httpx 0.27
- **BD Producción:** PostgreSQL en [Neon](https://neon.tech) (free tier)
- **BD Desarrollo:** SQLite (local)
- **Frontend:** HTML5, CSS3, JavaScript ES2022, Chart.js 4.4
- **Hosting:** Render.com (free tier web service)
- **Auth:** Header `X-Admin-Key` validado en cada petición admin

---

## Tipos de pregunta soportados

- **radio** — Opción única
- **checkbox** — Opción múltiple
- **select** — Lista desplegable
- **scale** — Escala numérica configurable (ej. 1–5)
- **text** — Texto corto
- **textarea** — Texto largo / párrafo

---

## Estructura del proyecto

```
Encuestas_Platform/
├── main.py               # FastAPI app principal
├── database.py           # Conexión SQLAlchemy (SQLite / PostgreSQL)
├── models.py             # Modelos: Survey, Question, Response, Answer
├── schemas.py            # Validación Pydantic
├── routers/
│   ├── admin.py          # CRUD encuestas, resultados, exportar CSV
│   └── public.py         # Ver encuesta + enviar respuesta
├── frontend/
│   ├── index.html        # Redirige a /admin/
│   ├── encuesta.html     # Página pública (link que se comparte)
│   └── admin/
│       ├── index.html    # Lista de encuestas
│       ├── crear.html    # Constructor de encuesta
│       └── resultados.html # Dashboard con gráficas Chart.js
├── requirements.txt
├── .env.example          # Plantilla de variables de entorno
└── start.bat             # Script de arranque para Windows
```

---

## Instalación y arranque

### Requisitos
- Python 3.10+ (Miniconda o instalación estándar)
- Las dependencias se instalan automáticamente

### Pasos

**1. Configurar variables de entorno**
```bash
copy .env.example .env
```
Edita `.env` y cambia `ADMIN_KEY` por una clave segura.

**2. Instalar dependencias**
```bash
pip install -r requirements.txt
```

**3. Arrancar el servidor**

Opción A — Doble clic en `start.bat`

Opción B — Desde terminal:
```bash
python -m uvicorn main:app --app-dir "RUTA_ABSOLUTA_AL_PROYECTO" --port 8002
```

**4. Acceder**

| URL | Descripción |
|-----|-------------|
| `http://localhost:8002/admin/` | Panel de administración |
| `http://localhost:8002/encuesta.html?s=SLUG` | Encuesta pública |

---

## Variables de entorno (`.env`)

```env
DATABASE_URL=sqlite:///./encuestas.db
ADMIN_KEY=tu_clave_segura_aqui
```

Para usar PostgreSQL en producción:
```env
DATABASE_URL=postgresql://usuario:password@localhost:5432/encuestas
```

---

## Flujo de uso

```
Admin crea encuesta → Obtiene URL → Comparte por correo/WhatsApp
       ↓
Destinatario responde en el navegador (sin login)
       ↓
Respuestas guardadas en la base de datos
       ↓
Admin ve dashboard con gráficas + exporta CSV
```

---

## API REST

El backend expone dos grupos de endpoints:

### Público (sin autenticación)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/encuesta/{slug}` | Obtener datos de la encuesta |
| POST | `/api/encuesta/{slug}/responder` | Enviar respuesta |

### Admin (requiere header `X-Admin-Key`)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/admin/surveys` | Listar encuestas |
| POST | `/api/admin/surveys` | Crear encuesta |
| PATCH | `/api/admin/surveys/{slug}/toggle` | Activar/pausar |
| DELETE | `/api/admin/surveys/{slug}` | Eliminar |
| GET | `/api/admin/surveys/{slug}/results` | Resultados con conteos |
| GET | `/api/admin/surveys/{slug}/export` | Exportar CSV |

---

## Nota sobre puertos

El proyecto corre en el **puerto 8002** porque el 8000 puede estar ocupado por otros proyectos del workspace (ej. CRM_Ventas_).

Si necesitas cambiarlo, edita la última línea de `start.bat`.

---

## Tecnologías

- **Backend:** FastAPI 0.115, SQLAlchemy 2.0, SQLite (dev) / PostgreSQL (prod)
- **Frontend:** HTML5, CSS3, JavaScript ES2022, Chart.js 4.4
- **Auth:** Header `X-Admin-Key` validado en cada petición admin
