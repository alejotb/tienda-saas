-- Migración de datos
INSERT INTO notificaciones_base (titulo, mensaje, tipo, link, fecha_creacion)
SELECT DISTINCT titulo, mensaje, tipo, link, created_at
FROM notificaciones;

INSERT INTO notificaciones_usuario (notification_id, user_id, leido)
SELECT nb.id, n.user_id, n.leido
FROM notificaciones n
JOIN notificaciones_base nb ON n.titulo = nb.titulo AND n.mensaje = nb.mensaje AND n.created_at = nb.fecha_creacion;
