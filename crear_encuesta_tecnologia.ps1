$body = @{
    title       = "Encuesta de Necesidades Tecnológicas"
    description = "Ayúdanos a entender las herramientas y procesos que necesita tu área para trabajar mejor con datos y tecnología."
    questions   = @(

        # ── SECCIÓN 1: Datos Generales ──────────────────────────────────────
        @{ order = 1;  type = "text";     label = "Nombre completo";       required = $true;  options = $null }
        @{ order = 2;  type = "text";     label = "Correo electrónico";    required = $false; options = $null }
        @{
            order    = 3
            type     = "select"
            label    = "Departamento / Área"
            required = $true
            options  = @(
                "Dirección General"
                "Dirección Comercial"
                "Dirección de Operaciones"
                "Administración"
                "Contabilidad / Finanzas"
                "Recursos Humanos"
                "Tecnologías de la Información"
                "Almacén / Logística"
                "Ventas"
                "Compras"
                "Otro"
            )
        }
        @{ order = 4;  type = "text";     label = "Puesto / Cargo";        required = $true;  options = $null }

        # ── SECCIÓN 2: Situación Actual ──────────────────────────────────────
        @{
            order    = 5
            type     = "checkbox"
            label    = "¿Cuál es la herramienta principal que usa hoy para gestionar información o procesos? (puedes seleccionar varias)"
            required = $false
            options  = @(
                "Excel / Hoja de cálculo"
                "Sistema ERP (SAP, Odoo, etc.)"
                "Aplicación interna de la empresa"
                "Papel / Documentos físicos"
                "Correo electrónico"
                "Otra"
            )
        }
        @{ order = 6; type = "text"; label = "Si seleccionaste 'Otra' herramienta, especifica cuál:"; required = $false; options = $null }
        @{
            order    = 7
            type     = "select"
            label    = "¿Cuánto tiempo dedica a tareas manuales o repetitivas en su área? (por semana estimado)"
            required = $false
            options  = @(
                "Menos de 2 horas"
                "Entre 2 y 5 horas"
                "Entre 5 y 10 horas"
                "Más de 10 horas"
            )
        }
        @{ order = 8; type = "textarea"; label = "¿Cuáles son los principales problemas o cuellos de botella actuales?"; required = $false; options = $null }

        # ── SECCIÓN 3: Tipo de Solución ──────────────────────────────────────
        @{
            order    = 9
            type     = "checkbox"
            label    = "¿Qué tipo de solución considera más útil para su área? (puedes seleccionar varias)"
            required = $false
            options  = @(
                "Automatización en Excel (macros, Power Query, fórmulas avanzadas)"
                "Dashboard / Reporte visual (Power BI, Google Looker Studio)"
                "Aplicación web interna (formularios, catálogos, consultas)"
                "Aplicación móvil (captura de datos en campo)"
                "Automatización de correos / notificaciones automáticas"
                "Base de datos centralizada (reemplazar archivos dispersos)"
                "Integración entre sistemas (conectar ERP, Excel, correo, etc.)"
                "Capacitación / formación en herramientas existentes"
                "No tengo claro qué necesito (requiero asesoría)"
            )
        }
        @{ order = 10; type = "textarea"; label = "Si eligió Aplicación web o móvil, ¿para qué proceso específico la necesitaría?"; required = $false; options = $null }

        # ── SECCIÓN 4: Prioridades ────────────────────────────────────────────
        @{
            order    = 11
            type     = "scale"
            label    = "¿Qué tanto impacto tendría una solución tecnológica en su área? (1 = Poco impacto, 5 = Impacto muy alto)"
            required = $true
            options  = @{ min = 1; max = 5; min_label = "Poco impacto"; max_label = "Impacto muy alto" }
        }
        @{
            order    = 12
            type     = "radio"
            label    = "¿Cuál es la urgencia de implementar una solución?"
            required = $true
            options  = @(
                "Inmediata - ya está afectando los resultados del área"
                "Corto plazo - próximos 3 meses"
                "Mediano plazo - 3 a 6 meses"
                "Sin urgencia definida por el momento"
            )
        }
        @{
            order    = 13
            type     = "radio"
            label    = "¿Estaría dispuesto a participar activamente en el diseño/prueba de una solución?"
            required = $false
            options  = @(
                "Sí, con gusto"
                "Sí, dependiendo de la disponibilidad de tiempo"
                "No en este momento"
            )
        }

        # ── SECCIÓN 5: Impacto Esperado ───────────────────────────────────────
        @{
            order    = 14
            type     = "checkbox"
            label    = "¿Qué mejoras esperas al implementar un nuevo software o mejorar procesos? (puedes seleccionar varias)"
            required = $false
            options  = @(
                "Ahorro de tiempo"
                "Reducción de errores"
                "Mejor control"
                "Mejores reportes"
                "Mejor experiencia del cliente/usuario"
            )
        }

        # ── SECCIÓN 6: Integración y Colaboración ─────────────────────────────
        @{ order = 15; type = "textarea"; label = "¿Con qué otras áreas necesitas intercambiar información?";          required = $false; options = $null }
        @{ order = 16; type = "textarea"; label = "¿Cómo se realiza actualmente esa comunicación?";                    required = $false; options = $null }
        @{ order = 17; type = "textarea"; label = "¿Qué problemas existen en la coordinación entre áreas?";            required = $false; options = $null }
        @{
            order    = 18
            type     = "radio"
            label    = "¿Te sería útil un sistema compartido o integrado entre áreas?"
            required = $false
            options  = @("Sí", "No")
        }

        # ── SECCIÓN 7: Necesidades de Software ───────────────────────────────
        @{ order = 19; type = "textarea"; label = "¿Para qué procesos necesitaría el sistema?";         required = $false; options = $null }
        @{ order = 20; type = "textarea"; label = "¿Qué funcionalidades debería tener?";                required = $false; options = $null }
        @{
            order    = 21
            type     = "radio"
            label    = "¿Preferirías un software existente o desarrollado a la medida?"
            required = $false
            options  = @(
                "Un software existente (comprado/licenciado)"
                "Un software desarrollado a la medida"
                "No lo sé"
            )
        }
        @{ order = 22; type = "textarea"; label = "¿Conoces alguna aplicación existente que cubra este requerimiento o que tenga funcionalidades similares a las que necesitas?"; required = $false; options = $null }

        # ── SECCIÓN 8: Comentarios Adicionales ───────────────────────────────
        @{ order = 23; type = "textarea"; label = "¿Hay algo más que quieras compartir sobre las necesidades de tu área?";      required = $false; options = $null }
        @{ order = 24; type = "textarea"; label = "¿Tienes alguna solución específica en mente que te gustaría proponer?";      required = $false; options = $null }
    )
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri     "https://encuesta-tecnologia.onrender.com/api/admin/surveys" `
    -Method  POST `
    -Headers @{ "Content-Type" = "application/json"; "X-Admin-Key" = "EncuestasIT01" } `
    -Body    $body

Write-Host ""
Write-Host "✅ Encuesta creada exitosamente" -ForegroundColor Green
Write-Host "   Slug  : $($response.slug)"
Write-Host "   ID    : $($response.id)"
Write-Host "   Link  : https://encuesta-tecnologia.onrender.com/encuesta.html?s=$($response.slug)"
Write-Host ""
