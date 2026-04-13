# =============================================================================
# setup_servidor.ps1 — Deploy de Encuestas_Platform en el servidor dedicado
# Ejecutar en el SERVIDOR (RDP) como Administrador desde C:\WINDOWS\system32
# =============================================================================
# USO:
#   1. Copiar este archivo al servidor (o clonarlo desde GitHub)
#   2. Abrir PowerShell como Administrador
#   3. Set-ExecutionPolicy Bypass -Scope Process -Force
#   4. .\setup_servidor.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

# ── CONFIGURACIÓN ────────────────────────────────────────────────────────────
$REPO_URL    = "https://github.com/kayab23/encuesta-tecnologia.git"
$BASE_DIR    = "C:\ENCUESTAS"
$APP_DIR     = "$BASE_DIR\app"
$VENV_DIR    = "$BASE_DIR\venv"
$LOGS_DIR    = "$BASE_DIR\logs"
$DB_PATH     = "$BASE_DIR\encuestas.db"
$PORT        = 8003
$SERVICE     = "EncuestasBackend"
$CF_SERVICE  = "CloudflaredEncuestas"
$ADMIN_KEY   = "anuar2309"
$SURVEY_SLUG = "encuesta-de-necesidades-tecnologicas"

# Cloudflared exe — reutiliza el del CRM si existe, si no descarga
$CF_EXE = if (Test-Path "C:\CRM\cloudflared.exe") { "C:\CRM\cloudflared.exe" } else { "$BASE_DIR\cloudflared.exe" }

Write-Host "=== ENCUESTAS PLATFORM — SETUP SERVIDOR ===" -ForegroundColor Cyan

# ── 1. CREAR DIRECTORIOS ─────────────────────────────────────────────────────
Write-Host "[1/10] Creando directorios..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $BASE_DIR  | Out-Null
New-Item -ItemType Directory -Force -Path $LOGS_DIR  | Out-Null

# ── 2. CLONAR REPO ───────────────────────────────────────────────────────────
Write-Host "[2/10] Clonando repositorio..." -ForegroundColor Yellow
if (Test-Path "$APP_DIR\.git") {
    Write-Host "       Repo ya existe — haciendo pull..." -ForegroundColor Gray
    Set-Location $APP_DIR
    git reset --hard origin/main
    git pull origin main
} else {
    git clone --branch main $REPO_URL $APP_DIR
}

# ── 3. CREAR VENV E INSTALAR DEPENDENCIAS ────────────────────────────────────
Write-Host "[3/10] Creando entorno virtual Python..." -ForegroundColor Yellow
if (-not (Test-Path "$VENV_DIR\Scripts\python.exe")) {
    python -m venv $VENV_DIR
}
Write-Host "       Instalando dependencias..." -ForegroundColor Gray
& "$VENV_DIR\Scripts\pip.exe" install --upgrade pip --quiet
& "$VENV_DIR\Scripts\pip.exe" install -r "$APP_DIR\requirements.txt" --quiet

# ── 4. CREAR ARCHIVO .env ────────────────────────────────────────────────────
Write-Host "[4/10] Creando archivo .env..." -ForegroundColor Yellow
$envContent = @"
DATABASE_URL=sqlite:///$($DB_PATH.Replace('\', '/'))
ADMIN_KEY=$ADMIN_KEY
"@
Set-Content -Path "$APP_DIR\.env" -Value $envContent -Encoding UTF8
Write-Host "       .env creado: DATABASE_URL apunta a $DB_PATH" -ForegroundColor Gray

# ── 5. DETENER SERVICIO ANTERIOR (si existe) ──────────────────────────────────
Write-Host "[5/10] Verificando servicios existentes..." -ForegroundColor Yellow
if (Get-Service $SERVICE -ErrorAction SilentlyContinue) {
    Write-Host "       Deteniendo servicio $SERVICE existente..." -ForegroundColor Gray
    nssm stop $SERVICE confirm
    nssm remove $SERVICE confirm
}
if (Get-Service $CF_SERVICE -ErrorAction SilentlyContinue) {
    nssm stop $CF_SERVICE confirm
    nssm remove $CF_SERVICE confirm
}

# ── 6. REGISTRAR SERVICIO NSSM — BACKEND ─────────────────────────────────────
Write-Host "[6/10] Registrando servicio NSSM $SERVICE..." -ForegroundColor Yellow
nssm install $SERVICE "$VENV_DIR\Scripts\uvicorn.exe"
nssm set $SERVICE AppDirectory $APP_DIR
nssm set $SERVICE AppParameters "main:app --host 127.0.0.1 --port $PORT --workers 2"
nssm set $SERVICE AppEnvironmentExtra "PYTHONPATH=$APP_DIR"
nssm set $SERVICE AppStdout "$LOGS_DIR\backend.log"
nssm set $SERVICE AppStderr "$LOGS_DIR\backend.log"
nssm set $SERVICE AppRotateFiles 1
nssm set $SERVICE AppRotateBytes 10485760
nssm set $SERVICE Start SERVICE_AUTO_START
Start-Service $SERVICE
Start-Sleep -Seconds 3
$svc = Get-Service $SERVICE
Write-Host "       Estado: $($svc.Status)" -ForegroundColor $(if ($svc.Status -eq 'Running') { 'Green' } else { 'Red' })

# ── 7. CLOUDFLARE QUICK TUNNEL ───────────────────────────────────────────────
Write-Host "[7/10] Configurando Cloudflare Tunnel..." -ForegroundColor Yellow
if (-not (Test-Path $CF_EXE)) {
    Write-Host "       Descargando cloudflared..." -ForegroundColor Gray
    $cfUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    Invoke-WebRequest -Uri $cfUrl -OutFile $CF_EXE
}
nssm install $CF_SERVICE $CF_EXE
nssm set $CF_SERVICE AppParameters "tunnel --url http://localhost:$PORT"
nssm set $CF_SERVICE AppStdout "$LOGS_DIR\cloudflared.log"
nssm set $CF_SERVICE AppStderr "$LOGS_DIR\cloudflared.log"
nssm set $CF_SERVICE Start SERVICE_AUTO_START
Start-Service $CF_SERVICE

# Esperar a que aparezca la URL en el log
Write-Host "       Esperando URL de Cloudflare (15 seg)..." -ForegroundColor Gray
Start-Sleep -Seconds 15
$cfUrl = Select-String -Path "$LOGS_DIR\cloudflared.log" -Pattern "trycloudflare\.com" |
         Select-Object -Last 1 |
         ForEach-Object { ($_.Line -split '"' | Where-Object { $_ -match 'https://.*trycloudflare' }) | Select-Object -First 1 }

if (-not $cfUrl) {
    # Segundo intento con otro patrón
    $cfUrl = Select-String -Path "$LOGS_DIR\cloudflared.log" -Pattern "https://.*\.trycloudflare\.com" |
             Select-Object -Last 1 |
             ForEach-Object { [regex]::Match($_.Line, 'https://[^\s"]+trycloudflare\.com').Value }
}

Write-Host ""
Write-Host "=== URL PÚBLICA CLOUDFLARE ===" -ForegroundColor Cyan
Write-Host $cfUrl -ForegroundColor Green
Write-Host ""

# ── 8. CREAR LA ENCUESTA EN LA BD ────────────────────────────────────────────
Write-Host "[8/10] Creando encuesta con 24 preguntas en la BD..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$surveyBody = @{
    title       = "Encuesta de Necesidades Tecnológicas"
    slug        = $SURVEY_SLUG
    description = "Diagnóstico interno de necesidades tecnológicas por área"
    questions   = @(
        @{ label = "Nombre completo";                                   type = "text";     required = $true  }
        @{ label = "Correo electrónico";                                type = "email";    required = $false }
        @{ label = "Departamento / Área";                               type = "text";     required = $true  }
        @{ label = "Puesto / Cargo";                                    type = "text";     required = $true  }
        @{ label = "Herramienta principal actual";                      type = "checkbox"; required = $false }
        @{ label = "Tiempo en tareas manuales por semana";              type = "select";   required = $false }
        @{ label = "Principales problemas o cuellos de botella";        type = "textarea"; required = $false }
        @{ label = "Tipo de solución deseada";                         type = "checkbox"; required = $false }
        @{ label = "Detalle de aplicación web o móvil deseada";        type = "textarea"; required = $false }
        @{ label = "Impacto esperado de solución tecnológica (1-5)";   type = "scale";    required = $true  }
        @{ label = "Urgencia de implementación";                        type = "radio";    required = $true  }
        @{ label = "Disponibilidad para participar en diseño/prueba";  type = "radio";    required = $false }
        @{ label = "Mejoras esperadas al implementar nuevo software";  type = "checkbox"; required = $false }
        @{ label = "Áreas con las que necesita intercambiar información"; type = "textarea"; required = $false }
        @{ label = "Cómo se realiza actualmente la comunicación entre áreas"; type = "textarea"; required = $false }
        @{ label = "Problemas en la coordinación entre áreas";         type = "textarea"; required = $false }
        @{ label = "Utilidad de un sistema compartido entre áreas";    type = "radio";    required = $false }
        @{ label = "¿El área necesita un nuevo sistema o aplicación?"; type = "radio";    required = $false }
        @{ label = "Procesos que requieren nuevo sistema";             type = "textarea"; required = $false }
        @{ label = "Funcionalidades requeridas del nuevo sistema";     type = "textarea"; required = $false }
        @{ label = "Preferencia de tipo de software";                  type = "radio";    required = $false }
        @{ label = "Criticidad de la solución necesaria";              type = "radio";    required = $false }
        @{ label = "Comentarios adicionales";                          type = "textarea"; required = $false }
        @{ label = "Propuesta de solución específica";                 type = "textarea"; required = $false }
    )
} | ConvertTo-Json -Depth 5

try {
    $result = Invoke-RestMethod -Uri "http://127.0.0.1:$PORT/api/admin/surveys" `
        -Method POST `
        -Headers @{ "x-admin-key" = $ADMIN_KEY; "Content-Type" = "application/json" } `
        -Body $surveyBody
    Write-Host "       Encuesta creada — slug: $($result.slug)" -ForegroundColor Green
} catch {
    Write-Host "       AVISO: $($_.Exception.Message) (puede que ya exista)" -ForegroundColor DarkYellow
}

# ── 9. VERIFICACIÓN FINAL ────────────────────────────────────────────────────
Write-Host "[9/10] Verificación de servicios..." -ForegroundColor Yellow
$statusBackend = (Get-Service $SERVICE).Status
$statusCF      = (Get-Service $CF_SERVICE).Status
Write-Host "       $SERVICE   : $statusBackend" -ForegroundColor $(if ($statusBackend -eq 'Running') { 'Green' } else { 'Red' })
Write-Host "       $CF_SERVICE : $statusCF"    -ForegroundColor $(if ($statusCF      -eq 'Running') { 'Green' } else { 'Red' })

# ── 10. RESUMEN FINAL ────────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " DEPLOY COMPLETADO" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Backend local : http://127.0.0.1:$PORT"
Write-Host " URL pública   : $cfUrl"
Write-Host " Admin key     : $ADMIN_KEY"
Write-Host " BD            : $DB_PATH"
Write-Host " Logs          : $LOGS_DIR"
Write-Host ""
Write-Host " IMPORTANTE: Actualiza la URL en encuesta_necesidades_tecnologia.html:"
Write-Host " SURVEY_URL = '$cfUrl/api/encuesta/$SURVEY_SLUG/responder'"
Write-Host "============================================" -ForegroundColor Cyan
