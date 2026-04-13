# Infraestructura de Producción — CRM de Visitas Médicas

> **Propósito:** Instrucciones precisas para que otro agente IA pueda desplegar
> un nuevo proyecto en el mismo servidor utilizando exactamente el mismo patrón.

---

## 1. Servidor de Producción

| Atributo | Valor |
|---|---|
| **Hardware** | HP ProLiant ML30 Gen10 |
| **SO** | Windows Server 2022 Standard |
| **IP interna** | `192.168.1.250` |
| **Acceso** | RDP + NSSM (servicios Windows nativos) |
| **Administrador** | Usuario con privilegios de Administrador |
| **Shell de trabajo** | PowerShell como Administrador desde `C:\WINDOWS\system32` |

---

## 2. Stack de tecnologías instaladas globalmente

| Componente | Versión | Ruta / Comando |
|---|---|---|
| Python | 3.11–3.13 | `python` en PATH |
| Node.js | 20 LTS | `node` en PATH |
| npm | incluido con Node | `npm` en PATH |
| PostgreSQL | 17 | `C:\Program Files\PostgreSQL\17\bin\` en PATH |
| Git | for Windows | `git` en PATH |
| NSSM | 2.24 | `nssm.exe` en `C:\Windows\System32\` (en PATH) |
| cloudflared | latest | `C:\CRM\cloudflared.exe` o en PATH |
| nginx | 1.26.2 | `C:\CRM\nginx\nginx.exe` (si se reutiliza el mismo), o instalar en `C:\PROYECTO\nginx\` |

---

## 3. Estructura de directorios — patrón usado

Cada proyecto sigue este esquema. El proyecto CRM está en `C:\CRM`, un nuevo proyecto irá en `C:\PROYECTO_NOMBRE`:

```
C:\PROYECTO_NOMBRE\
├── app\                        ← git clone del repo (código fuente)
│   ├── backend\
│   │   ├── app\                ← FastAPI (main.py, routers/, models/, etc.)
│   │   ├── alembic\            ← migraciones
│   │   ├── requirements.txt
│   │   ├── seeds.py            ← datos iniciales
│   │   └── .env                ← variables de entorno (NO en git)
│   ├── frontend\
│   │   ├── src\                ← Vue 3 + Vite
│   │   ├── dist\               ← build compilado (generado por npm run build)
│   │   └── package.json
│   ├── deploy.ps1              ← script de auto-deploy
│   └── setup.ps1               ← script de instalación inicial (único uso)
├── venv\                       ← entorno virtual Python (fuera del repo)
├── nginx\                      ← nginx para Windows (si no se comparte)
└── logs\
    ├── deploy.log
    ├── backend.log
    └── nginx.log
```

---

## 4. Servicios NSSM — patrón CRM (replicar para nuevo proyecto)

### Proyecto CRM (referencia activa)

| Servicio NSSM | Descripción | Puerto | Binario |
|---|---|---|---|
| `KezelCRM` | Backend FastAPI (uvicorn) | `127.0.0.1:8002` | `C:\CRM\venv\Scripts\uvicorn.exe` |
| `KezelNginx` | nginx (frontend + proxy API) | `0.0.0.0:80` | `C:\CRM\nginx\nginx.exe` |
| `CloudflaredCRM` | Cloudflare Tunnel (acceso externo) | — | `C:\CRM\cloudflared.exe` |
| `KezelCRM-AutoDeploy` | Tarea programada (cada 10 min) | — | Tarea Programada de Windows |

### Para un nuevo proyecto (ejemplo: `MiApp`)

```
Servicio       : MiAppBackend   (puerto: 8003 o siguiente disponible)
Servicio       : MiAppNginx     (puerto: 81 o siguiente disponible)
Servicio       : CloudflaredMiApp
Tarea prog.    : MiApp-AutoDeploy
Directorio     : C:\MIAPP\
BD             : miapp_db  /  miapp_user  /  miapp_pass_2026
```

---

## 5. Puertos en uso (evitar colisiones)

| Puerto | Ocupado por |
|---|---|
| `80` | KezelNginx (frontend CRM) |
| `5432` | PostgreSQL 17 |
| `8001` | Costos Vitaris FastAPI |
| `8002` | KezelCRM FastAPI (backend CRM visitas) |
| `8003` | ← disponible para siguiente proyecto |
| `8004` | ← disponible |

---

## 6. PostgreSQL — crear BD para nuevo proyecto

Ejecutar como Administrador en el servidor:

```powershell
$env:PGPASSWORD = "PASSWORD_POSTGRES_SUPERUSUARIO"
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"

# Crear usuario
& $psql -U postgres -h localhost -c "CREATE USER miapp_user WITH PASSWORD 'miapp_pass_2026';"

# Crear base de datos
& $psql -U postgres -h localhost -c "CREATE DATABASE miapp_db OWNER miapp_user ENCODING 'UTF8';"
& $psql -U postgres -h localhost -c "GRANT ALL PRIVILEGES ON DATABASE miapp_db TO miapp_user;"
```

**Cadena de conexión:** `postgresql://miapp_user:miapp_pass_2026@localhost:5432/miapp_db`

---

## 7. Variables de entorno — archivo `.env` (NO va en git)

Crear manualmente en `C:\MIAPP\app\backend\.env`:

```env
DATABASE_URL=postgresql://miapp_user:miapp_pass_2026@localhost:5432/miapp_db
SECRET_KEY=GENERAR_64_CHARS_ALEATORIOS
ACCESS_TOKEN_EXPIRE_MINUTES=480
REFRESH_TOKEN_EXPIRE_DAYS=7
ALGORITHM=HS256
FRONTEND_ORIGIN=https://URL_DE_CLOUDFLARE_TUNNEL

# Alertas email (opcional)
REPAIR_ENABLED=true
ALERT_ENABLED=true
ALERT_EMAIL_FROM=ferdesarrolloapps@gmail.com
ALERT_EMAIL_PASS=weqcvjxslbbmusni
ALERT_EMAIL_TO=ferdesarrolloapps@gmail.com
ALERT_COOLDOWN_MIN=15
```

Generar SECRET_KEY con PowerShell:
```powershell
-join ((65..90)+(97..122)+(48..57) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

---

## 8. nginx — configuración tipo para nuevo proyecto

```nginx
# C:\MIAPP\nginx\conf\nginx.conf
worker_processes auto;
events { worker_connections 2048; }
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;
    gzip_min_length 1024;
    gzip_comp_level 5;

    server {
        listen 81;                              # <-- puerto distinto al CRM
        root C:/MIAPP/app/frontend/dist;
        index index.html;

        location /api/ {
            proxy_pass http://127.0.0.1:8003/; # <-- puerto del backend
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-Proto https;
            proxy_read_timeout 60s;
        }

        location / { try_files $uri $uri/ /index.html; }
        location ~ /\. { deny all; }
    }
}
```

---

## 9. Registrar servicios NSSM — comandos exactos

```powershell
# ── BACKEND ──────────────────────────────────────────────────────
nssm install MiAppBackend "C:\MIAPP\venv\Scripts\uvicorn.exe"
nssm set MiAppBackend AppDirectory "C:\MIAPP\app\backend"
nssm set MiAppBackend AppParameters "app.main:app --host 127.0.0.1 --port 8003 --workers 4"
nssm set MiAppBackend AppEnvironmentExtra "PYTHONPATH=C:\MIAPP\app\backend"
nssm set MiAppBackend AppStdout "C:\MIAPP\logs\backend.log"
nssm set MiAppBackend AppStderr "C:\MIAPP\logs\backend.log"
nssm set MiAppBackend AppRotateFiles 1
nssm set MiAppBackend AppRotateBytes 10485760
nssm set MiAppBackend Start SERVICE_AUTO_START
Start-Service MiAppBackend

# ── NGINX ────────────────────────────────────────────────────────
nssm install MiAppNginx "C:\MIAPP\nginx\nginx.exe"
nssm set MiAppNginx AppDirectory "C:\MIAPP\nginx"
nssm set MiAppNginx AppStdout "C:\MIAPP\logs\nginx.log"
nssm set MiAppNginx AppStderr "C:\MIAPP\logs\nginx-error.log"
nssm set MiAppNginx Start SERVICE_AUTO_START
Start-Service MiAppNginx

# ── CLOUDFLARE TUNNEL ────────────────────────────────────────────
# Modo rápido (URL aleatoria temporal — para pruebas):
nssm install CloudflaredMiApp "C:\MIAPP\cloudflared.exe"
nssm set CloudflaredMiApp AppParameters "tunnel --url http://localhost:81"
nssm set CloudflaredMiApp AppStdout "C:\MIAPP\logs\cloudflared.log"
nssm set CloudflaredMiApp AppStderr "C:\MIAPP\logs\cloudflared.log"
nssm set CloudflaredMiApp Start SERVICE_AUTO_START
Start-Service CloudflaredMiApp
# La URL pública aparece en C:\MIAPP\logs\cloudflared.log (buscar "trycloudflare.com")
```

---

## 10. Auto-deploy — tarea programada (cada 10 min)

Crear `C:\MIAPP\app\deploy.ps1` (copiar y adaptar de `C:\CRM\app\deploy.ps1`):

```powershell
# Registrar la tarea programada:
$action  = New-ScheduledTaskAction -Execute "powershell.exe" `
           -Argument '-NonInteractive -ExecutionPolicy Bypass -File "C:\MIAPP\app\deploy.ps1"'
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 10) -Once -At (Get-Date)
$settings= New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 8) -MultipleInstances IgnoreNew
Register-ScheduledTask -TaskName "MiApp-AutoDeploy" -Action $action -Trigger $trigger `
    -Settings $settings -RunLevel Highest -Force
```

**El deploy.ps1 hace:**
1. `git fetch origin` → compara hash local vs remoto
2. Si hay cambios: `git reset --hard origin/main`
3. `npm run build` (recompila frontend)
4. `pip install -r requirements.txt` (instala nuevas dependencias)
5. `alembic upgrade head` (aplica migraciones)
6. `nssm restart MiAppBackend`

---

## 11. Vite — configuración frontend para que `/api/` apunte al backend

En `frontend/vite.config.ts` (desarrollo local):

```typescript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8003',  // puerto del backend local
      rewrite: (path) => path.replace(/^\/api/, ''),
    }
  }
}
```

En `src/api/client.ts`:

```typescript
const api = axios.create({
  baseURL: '/api',       // nginx hace el proxy en producción
  withCredentials: true, // necesario para cookies httpOnly (refresh token)
})
```

---

## 12. Checklist de instalación inicial — nuevo proyecto

Ejecutar en orden desde el servidor (`C:\WINDOWS\system32`, como Administrador):

```powershell
# 1. Clonar repo
git clone --branch main "https://TOKEN@github.com/USER/REPO.git" "C:\MIAPP\app"

# 2. Crear venv
python -m venv "C:\MIAPP\venv"

# 3. Instalar dependencias Python
& "C:\MIAPP\venv\Scripts\pip.exe" install -r "C:\MIAPP\app\backend\requirements.txt"

# 4. Crear .env (ver sección 7)
# (editar manualmente C:\MIAPP\app\backend\.env)

# 5. Crear BD en PostgreSQL (ver sección 6)

# 6. Correr migraciones
$env:PYTHONPATH = "C:\MIAPP\app\backend"
& "C:\MIAPP\venv\Scripts\python.exe" -m alembic -c "C:\MIAPP\app\backend\alembic.ini" upgrade head

# 7. Seeds iniciales
& "C:\MIAPP\venv\Scripts\python.exe" "C:\MIAPP\app\backend\seeds.py"

# 8. Compilar frontend
Set-Location "C:\MIAPP\app\frontend"; npm install; npm run build

# 9. Configurar nginx (ver sección 8)

# 10. Registrar servicios NSSM (ver sección 9)

# 11. Registrar tarea programada (ver sección 10)

# 12. Verificar
nssm status MiAppBackend   # debe decir: SERVICE_RUNNING
nssm status MiAppNginx     # debe decir: SERVICE_RUNNING
Invoke-RestMethod "http://127.0.0.1:8003/health"
```

---

## 13. Comandos de operación diaria

```powershell
# Ver estado de todos los servicios del CRM
nssm status KezelCRM; nssm status KezelNginx; nssm status CloudflaredCRM

# Reiniciar backend (tras cambio de .env o config)
nssm restart KezelCRM

# Forzar deploy inmediato
cd C:\CRM\app; .\deploy.ps1

# Ver últimas líneas del log
Get-Content C:\CRM\logs\deploy.log -Tail 30
Get-Content C:\CRM\logs\backend.log -Tail 50

# Ver URL del tunnel de Cloudflare (si es tunnel rápido)
Select-String "trycloudflare.com" C:\CRM\logs\cloudflared.log | Select-Object -Last 3

# Agregar variable de entorno al .env sin editar el archivo
Add-Content "C:\CRM\app\backend\.env" "`nNUEVA_VAR=valor"
nssm restart KezelCRM
```

---

## 14. Repositorio GitHub

| Campo | Valor |
|---|---|
| **URL** | `https://github.com/kayab23/Vistas_app.git` |
| **Rama productiva** | `main` |
| **Auth** | GitHub PAT (`ghp_...`) guardado en Windows Credential Manager |
| **Archivos en `.gitignore`** | `.env`, `venv/`, `dist/`, `__pycache__/`, `*.db`, `node_modules/` |

> ⚠️ **El `.env` NUNCA va en git.** Se crea manualmente en el servidor después del clone.

---

## 15. Proyecto CRM activo — referencia rápida

| Dato | Valor |
|---|---|
| Directorio | `C:\CRM\app\` |
| Backend URL interna | `http://127.0.0.1:8002` |
| Frontend acceso local | `http://127.0.0.1:80` |
| BD | `kezel_medica` / `kezel_user` / `kezel_pass_2026` |
| Admin app | `admin@kezelmedica.mx` / `Kezel2026!` |
| Swagger | `http://127.0.0.1:8002/docs` |
| Log deploy | `C:\CRM\logs\deploy.log` |
| Log backend | `C:\CRM\logs\backend.log` |
