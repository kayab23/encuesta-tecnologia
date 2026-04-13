# setup_servidor.ps1 - Deploy de Encuestas_Platform en el servidor dedicado
# Ejecutar como Administrador: Set-ExecutionPolicy Bypass -Scope Process -Force
# luego: .\setup_servidor.ps1

$ErrorActionPreference = "Stop"

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

if (Test-Path "C:\CRM\cloudflared.exe") {
    $CF_EXE = "C:\CRM\cloudflared.exe"
} else {
    $CF_EXE = "$BASE_DIR\cloudflared.exe"
}

Write-Host "[1/9] Creando directorios..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $BASE_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $LOGS_DIR | Out-Null

Write-Host "[2/9] Clonando o actualizando repo..." -ForegroundColor Yellow
$gitDir = Join-Path $APP_DIR ".git"
if (Test-Path $gitDir) {
    Set-Location $APP_DIR
    git reset --hard origin/main
    git pull origin main
} else {
    git clone --branch main $REPO_URL $APP_DIR
    Set-Location $APP_DIR
}

Write-Host "[3/9] Creando venv e instalando dependencias..." -ForegroundColor Yellow
$pythonExe = Join-Path $VENV_DIR "Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    python -m venv $VENV_DIR
}
$pipExe  = Join-Path $VENV_DIR "Scripts\pip.exe"
$reqFile = Join-Path $APP_DIR "requirements.txt"
& $pipExe install --upgrade pip --quiet
& $pipExe install -r $reqFile --quiet

Write-Host "[4/9] Creando .env..." -ForegroundColor Yellow
$dbFwd   = $DB_PATH.Replace('\', '/')
$envText = "DATABASE_URL=sqlite:///" + $dbFwd + "`nADMIN_KEY=" + $ADMIN_KEY
$envFile = Join-Path $APP_DIR ".env"
[System.IO.File]::WriteAllText($envFile, $envText, [System.Text.Encoding]::UTF8)

Write-Host "[5/9] Limpiando servicios anteriores..." -ForegroundColor Yellow
if (Get-Service $SERVICE -ErrorAction SilentlyContinue) {
    nssm stop $SERVICE confirm
    nssm remove $SERVICE confirm
}
if (Get-Service $CF_SERVICE -ErrorAction SilentlyContinue) {
    nssm stop $CF_SERVICE confirm
    nssm remove $CF_SERVICE confirm
}

Write-Host "[6/9] Registrando servicio NSSM backend..." -ForegroundColor Yellow
$uvicornExe = Join-Path $VENV_DIR "Scripts\uvicorn.exe"
$backendLog = Join-Path $LOGS_DIR "backend.log"
nssm install $SERVICE $uvicornExe
nssm set $SERVICE AppDirectory $APP_DIR
nssm set $SERVICE AppParameters "main:app --host 127.0.0.1 --port $PORT --workers 2"
nssm set $SERVICE AppEnvironmentExtra "PYTHONPATH=$APP_DIR"
nssm set $SERVICE AppStdout $backendLog
nssm set $SERVICE AppStderr $backendLog
nssm set $SERVICE AppRotateFiles 1
nssm set $SERVICE AppRotateBytes 10485760
nssm set $SERVICE Start SERVICE_AUTO_START
Start-Service $SERVICE
Start-Sleep -Seconds 3
Write-Host "       Estado: $((Get-Service $SERVICE).Status)" -ForegroundColor Green

Write-Host "[7/9] Configurando Cloudflare Tunnel..." -ForegroundColor Yellow
if (-not (Test-Path $CF_EXE)) {
    $cfDl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    Invoke-WebRequest -Uri $cfDl -OutFile $CF_EXE
}
$cfLog = Join-Path $LOGS_DIR "cloudflared.log"
nssm install $CF_SERVICE $CF_EXE
nssm set $CF_SERVICE AppParameters "tunnel --url http://localhost:$PORT"
nssm set $CF_SERVICE AppStdout $cfLog
nssm set $CF_SERVICE AppStderr $cfLog
nssm set $CF_SERVICE Start SERVICE_AUTO_START
Start-Service $CF_SERVICE
Write-Host "       Esperando URL Cloudflare (20 seg)..." -ForegroundColor Gray
Start-Sleep -Seconds 20

$cfPublicUrl = ""
$ml = Select-String -Path $cfLog -Pattern "trycloudflare\.com" -ErrorAction SilentlyContinue | Select-Object -Last 1
if ($ml) {
    $rm = [regex]::Match($ml.Line, 'https://[^\s"]+trycloudflare\.com')
    if ($rm.Success) { $cfPublicUrl = $rm.Value }
}

Write-Host "[8/9] Creando encuesta en la BD..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$q = @(
    @{ label = "Nombre completo";                                   type = "text";     required = $true  }
    @{ label = "Correo electronico";                                type = "email";    required = $false }
    @{ label = "Departamento o Area";                               type = "text";     required = $true  }
    @{ label = "Puesto o Cargo";                                    type = "text";     required = $true  }
    @{ label = "Herramienta principal actual";                      type = "checkbox"; required = $false }
    @{ label = "Tiempo en tareas manuales por semana";              type = "select";   required = $false }
    @{ label = "Principales problemas o cuellos de botella";        type = "textarea"; required = $false }
    @{ label = "Tipo de solucion deseada";                         type = "checkbox"; required = $false }
    @{ label = "Detalle de aplicacion web o movil deseada";        type = "textarea"; required = $false }
    @{ label = "Impacto esperado de solucion tecnologica (1-5)";   type = "scale";    required = $true  }
    @{ label = "Urgencia de implementacion";                        type = "radio";    required = $true  }
    @{ label = "Disponibilidad para participar en prueba";         type = "radio";    required = $false }
    @{ label = "Mejoras esperadas al implementar nuevo software";  type = "checkbox"; required = $false }
    @{ label = "Areas con las que necesita intercambiar info";     type = "textarea"; required = $false }
    @{ label = "Como se realiza la comunicacion entre areas";      type = "textarea"; required = $false }
    @{ label = "Problemas en la coordinacion entre areas";         type = "textarea"; required = $false }
    @{ label = "Utilidad de un sistema compartido entre areas";    type = "radio";    required = $false }
    @{ label = "El area necesita un nuevo sistema o aplicacion";   type = "radio";    required = $false }
    @{ label = "Procesos que requieren nuevo sistema";             type = "textarea"; required = $false }
    @{ label = "Funcionalidades requeridas del nuevo sistema";     type = "textarea"; required = $false }
    @{ label = "Preferencia de tipo de software";                  type = "radio";    required = $false }
    @{ label = "Criticidad de la solucion necesaria";              type = "radio";    required = $false }
    @{ label = "Comentarios adicionales";                          type = "textarea"; required = $false }
    @{ label = "Propuesta de solucion especifica";                 type = "textarea"; required = $false }
)

$body = @{
    title       = "Encuesta de Necesidades Tecnologicas"
    slug        = $SURVEY_SLUG
    description = "Diagnostico interno de necesidades tecnologicas"
    questions   = $q
} | ConvertTo-Json -Depth 5

try {
    $res = Invoke-RestMethod `
        -Uri "http://127.0.0.1:$PORT/api/admin/surveys" `
        -Method POST `
        -Headers @{ "x-admin-key" = $ADMIN_KEY; "Content-Type" = "application/json" } `
        -Body $body
    Write-Host "       Encuesta creada - slug: $($res.slug)" -ForegroundColor Green
} catch {
    Write-Host "       $($_.Exception.Message)" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " DEPLOY COMPLETADO" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Local  : http://127.0.0.1:$PORT"
Write-Host " Publica: $cfPublicUrl"
Write-Host " Key    : $ADMIN_KEY"
Write-Host " BD     : $DB_PATH"
Write-Host ""
Write-Host " URL para el HTML:"
Write-Host " $cfPublicUrl/api/encuesta/$SURVEY_SLUG/responder"
Write-Host "============================================" -ForegroundColor Cyan