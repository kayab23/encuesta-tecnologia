$body = @{
    title       = "Encuesta de Necesidades Tecnologicas"
    description = "Ayudanos a entender las herramientas y procesos que necesita tu area para trabajar mejor con datos y tecnologia."
    questions   = @(

        # ── SECCION 1: Datos Generales ──────────────────────────────────────
        @{ order = 1;  type = "text";     label = "Nombre completo";    required = $true;  options = $null }
        @{ order = 2;  type = "text";     label = "Correo electronico"; required = $false; options = $null }
        @{ order = 3;  type = "text";     label = "Departamento / Area"; required = $true; options = $null }
        @{ order = 4;  type = "text";     label = "Puesto / Cargo";     required = $true;  options = $null }

        # ── SECCION 2: Situacion Actual ──────────────────────────────────────
        @{
            order    = 5
            type     = "checkbox"
            label    = "Cual es la herramienta principal que usa hoy para gestionar informacion o procesos? (puedes seleccionar varias)"
            required = $false
            options  = @(
                "Excel / Hoja de calculo"
                "Sistema ERP (SAP, Odoo, etc.)"
                "Aplicacion interna de la empresa"
                "Papel / Documentos fisicos"
                "Correo electronico"
                "Otra"
            )
        }
        @{ order = 6; type = "text"; label = "Si seleccionaste 'Otra' herramienta, especifica cual:"; required = $false; options = $null }
        @{
            order    = 7
            type     = "select"
            label    = "Cuanto tiempo dedica a tareas manuales o repetitivas en su area? (por semana estimado)"
            required = $false
            options  = @(
                "Menos de 2 horas"
                "Entre 2 y 5 horas"
                "Entre 5 y 10 horas"
                "Mas de 10 horas"
            )
        }
        @{ order = 8; type = "textarea"; label = "Cuales son los principales problemas o cuellos de botella actuales?"; required = $false; options = $null }

        # ── SECCION 3: Tipo de Solucion ──────────────────────────────────────
        @{
            order    = 9
            type     = "checkbox"
            label    = "Que tipo de solucion considera mas util para su area? (puedes seleccionar varias)"
            required = $false
            options  = @(
                "Automatizacion en Excel (macros, Power Query, formulas avanzadas)"
                "Dashboard / Reporte visual (Power BI, Google Looker Studio)"
                "Aplicacion web interna (formularios, catalogos, consultas)"
                "Aplicacion movil (captura de datos en campo)"
                "Automatizacion de correos / notificaciones automaticas"
                "Base de datos centralizada (reemplazar archivos dispersos)"
                "Integracion entre sistemas (conectar ERP, Excel, correo, etc.)"
                "Capacitacion / formacion en herramientas existentes"
                "No tengo claro que necesito (requiero asesoria)"
            )
        }
        @{ order = 10; type = "textarea"; label = "Si eligio Aplicacion web o movil, para que proceso especifico la necesitaria?"; required = $false; options = $null }

        # ── SECCION 4: Prioridades ────────────────────────────────────────────
        @{
            order    = 11
            type     = "scale"
            label    = "Que tanto impacto tendria una solucion tecnologica en su area? (1 = Poco impacto, 5 = Impacto muy alto)"
            required = $true
            options  = @{ min = 1; max = 5; min_label = "Poco impacto"; max_label = "Impacto muy alto" }
        }
        @{
            order    = 12
            type     = "radio"
            label    = "Cual es la urgencia de implementar una solucion?"
            required = $true
            options  = @(
                "Inmediata - ya esta afectando los resultados del area"
                "Corto plazo - proximos 3 meses"
                "Mediano plazo - 3 a 6 meses"
                "Sin urgencia definida por el momento"
            )
        }
        @{
            order    = 13
            type     = "radio"
            label    = "Estaria dispuesto a participar activamente en el diseno/prueba de una solucion?"
            required = $false
            options  = @(
                "Si, con gusto"
                "Si, dependiendo de la disponibilidad de tiempo"
                "No en este momento"
            )
        }

        # ── SECCION 5: Impacto Esperado ───────────────────────────────────────
        @{
            order    = 14
            type     = "checkbox"
            label    = "Que mejoras esperas al implementar un nuevo software o mejorar procesos? (puedes seleccionar varias)"
            required = $false
            options  = @(
                "Ahorro de tiempo"
                "Reduccion de errores"
                "Mejor control"
                "Mejores reportes"
                "Mejor experiencia del cliente/usuario"
            )
        }

        # ── SECCION 6: Integracion y Colaboracion ─────────────────────────────
        @{ order = 15; type = "textarea"; label = "Con que otras areas necesitas intercambiar informacion?";           required = $false; options = $null }
        @{ order = 16; type = "textarea"; label = "Como se realiza actualmente esa comunicacion?";                     required = $false; options = $null }
        @{ order = 17; type = "textarea"; label = "Que problemas existen en la coordinacion entre areas?";             required = $false; options = $null }
        @{
            order    = 18
            type     = "radio"
            label    = "Te seria util un sistema compartido o integrado entre areas?"
            required = $false
            options  = @("Si", "No")
        }

        # ── SECCION 7: Necesidades de Software ───────────────────────────────
        @{
            order    = 19
            type     = "radio"
            label    = "Crees que el area necesita un nuevo sistema o aplicacion?"
            required = $false
            options  = @("Si", "No", "No estoy seguro/a")
        }
        @{ order = 20; type = "textarea"; label = "Para que procesos necesitaria el sistema?";           required = $false; options = $null }
        @{ order = 21; type = "textarea"; label = "Que funcionalidades deberia tener?";                  required = $false; options = $null }
        @{
            order    = 22
            type     = "radio"
            label    = "Preferirías un software existente o desarrollado a la medida?"
            required = $false
            options  = @(
                "Un software existente (comprado/licenciado)"
                "Un software desarrollado a la medida"
                "No lo se"
            )
        }
        @{
            order    = 23
            type     = "radio"
            label    = "Que tan critico es contar con esta solucion?"
            required = $false
            options  = @("Urgente", "Importante", "Deseable")
        }

        # ── SECCION 8: Comentarios Adicionales ───────────────────────────────
        @{ order = 24; type = "textarea"; label = "Hay algo mas que quieras compartir sobre las necesidades de tu area?";           required = $false; options = $null }
        @{ order = 25; type = "textarea"; label = "Tienes alguna solucion especifica en mente que te gustaria proponer?";           required = $false; options = $null }
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
