Análisis de SNS y SES en tu proyecto
Tu proyecto usa SNS para notificaciones broadcast (a todos los suscriptores) y SES para correos dirigidos (a usuarios específicos). El email remitente configurado es juanesdev221@gmail.com.

Flujos de prueba para SNS

# Flujo Endpoint Qué probar Correo esperado

1 Suscripción al topic POST /auth/signup Registrar un usuario nuevo. Al registrarse, su email se suscribe al topic SNS. El usuario recibe un correo de AWS Notifications pidiendo confirmar la suscripción. Debe confirmarla para recibir futuros mensajes.
2 Alerta del organizador POST /organizer/alerts (JWT ORGANIZER) Crear una alerta. Va a EventBridge → regla la reenvía al topic SNS. Todos los emails suscritos y confirmados reciben la alerta con título, tipo, audiencia y fecha.
3 Recordatorios automáticos Sin endpoint (cron cada 1 hora) Se ejecuta automáticamente. Busca eventos con reservas en las próximas 12h/24h y publica al topic SNS. Los suscritos reciben un recordatorio del evento.
4 Reporte listo (broadcast) POST /organizer/reports (JWT ORGANIZER) Solicitar un reporte. El report-processor publica al topic SNS cuando termina. Todos los suscritos reciben notificación de reporte disponible.
Flujos de prueba para SES

# Flujo Endpoint Qué probar Correo esperado

1 Confirmación de reserva POST /buyer/seats (JWT ATTENDEE) Reservar un asiento. La Lambda envía email directo vía SES. El comprador recibe un correo de confirmación de su reserva desde juanesdev221@gmail.com.
2 Evento editado PUT /organizer/events/{eventId} (JWT ORGANIZER) Editar un evento que tiene reservas activas. Cada usuario con reserva activa recibe un correo notificando los cambios del evento.
3 Evento cancelado DELETE /organizer/events/{eventId} (JWT ORGANIZER) Eliminar un evento con reservas. Cada usuario con reserva activa recibe un correo de cancelación.
4 Reporte listo (directo) POST /organizer/reports (JWT ORGANIZER) Solicitar reporte. El report-processor envía email directo al organizador con URL de descarga. El organizador recibe un correo con un link presignado de S3 para descargar el reporte.
Pasos recomendados para probar ambos servicios
Prerequisitos:

Verifica que juanesdev221@gmail.com esté verificado en SES (si estás en sandbox, también debes verificar los emails destinatarios).
Si estás en SES Sandbox, solo puedes enviar correos a emails verificados.
Prueba completa paso a paso:

POST /auth/signup → Registra un usuario con un email real → Revisa la bandeja de entrada por el correo de confirmación de suscripción SNS → Confirma la suscripción.
POST /auth/signup con login después → POST /buyer/seats → Reserva un asiento → Revisa el correo del comprador por la confirmación SES.
POST /organizer/alerts → Crea una alerta → Revisa que todos los suscritos reciban el correo SNS.
PUT /organizer/events/{id} → Edita un evento con reservas → Revisa que los usuarios con reserva reciban correo SES de actualización.
DELETE /organizer/events/{id} → Elimina un evento con reservas → Revisa correos SES de cancelación.
POST /organizer/reports → Genera un reporte → Revisa dos correos: uno SNS (broadcast) y uno SES (directo al organizador con link de descarga).
Importante: Si estás en SES sandbox, todos los emails destinatarios deben estar verificados en la consola de SES. El remitente siempre será juanesdev221@gmail.com.
