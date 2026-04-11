@echo off
echo =========================================
echo   Plataforma de Encuestas — Iniciando
echo =========================================
echo.

:: Verificar si existe .env
if not exist "%~dp0.env" (
    echo Copiando .env.example como .env...
    copy "%~dp0.env.example" "%~dp0.env"
    echo ** Edita el archivo .env y cambia ADMIN_KEY **
    pause
)

echo Servidor disponible en: http://localhost:8002
echo Panel admin en:         http://localhost:8002/admin/
echo.
echo Presiona Ctrl+C para detener.
echo.

python -m uvicorn main:app --app-dir "%~dp0" --port 8002
pause
