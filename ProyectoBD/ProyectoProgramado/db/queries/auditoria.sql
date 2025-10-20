-- Consultas de Auditoría para el Sistema de Reservas de Tour

-- 1. Ver todas las operaciones de auditoría ordenadas por fecha
SELECT 
    ao.idAuditoria,
    ao.userName,
    ao.tablaAfectada,
    ao.operacion,
    ao.registroId,
    ao.fechaOperacion,
    ao.ipAddress
FROM auditoria_operaciones ao
ORDER BY ao.fechaOperacion DESC;

-- 2. Ver accesos a endpoints por usuario
SELECT 
    aa.userName,
    aa.endpoint,
    aa.metodo,
    aa.codigoRespuesta,
    aa.fechaAcceso,
    aa.ipAddress
FROM auditoria_accesos aa
WHERE aa.userName = 'nombre_usuario'
ORDER BY aa.fechaAcceso DESC;

-- 3. Ver sesiones activas
SELECT 
    s.sessionID,
    s.userName,
    s.fechaInicio,
    s.ipAddress,
    s.userAgent,
    s.estado
FROM sesiones s
WHERE s.estado = 'ACTIVA'
ORDER BY s.fechaInicio DESC;

-- 4. Ver historial de sesiones de un usuario
SELECT 
    ases.userName,
    ases.fechaInicio,
    ases.fechaFin,
    ases.ipAddress,
    ases.estado
FROM auditoria_sesiones ases
WHERE ases.userName = 'nombre_usuario'
ORDER BY ases.fechaInicio DESC;

-- 5. Ver operaciones en una tabla específica
SELECT 
    ao.userName,
    ao.operacion,
    ao.registroId,
    ao.valoresAnteriores,
    ao.valoresNuevos,
    ao.fechaOperacion
FROM auditoria_operaciones ao
WHERE ao.tablaAfectada = 'reserva'
ORDER BY ao.fechaOperacion DESC;

-- 6. Ver accesos fallidos (códigos de error)
SELECT 
    aa.userName,
    aa.endpoint,
    aa.metodo,
    aa.codigoRespuesta,
    aa.fechaAcceso,
    aa.ipAddress
FROM auditoria_accesos aa
WHERE aa.codigoRespuesta >= 400
ORDER BY aa.fechaAcceso DESC;

-- 7. Ver actividad de un usuario en un rango de fechas
SELECT 
    'ACCESO' as tipo,
    aa.userName,
    aa.endpoint as detalle,
    aa.fechaAcceso as fecha,
    aa.ipAddress
FROM auditoria_accesos aa
WHERE aa.userName = 'nombre_usuario'
    AND aa.fechaAcceso BETWEEN '2025-01-01' AND '2025-12-31'

UNION ALL

SELECT 
    'OPERACION' as tipo,
    ao.userName,
    CONCAT(ao.tablaAfectada, ' - ', ao.operacion) as detalle,
    ao.fechaOperacion as fecha,
    ao.ipAddress
FROM auditoria_operaciones ao
WHERE ao.userName = 'nombre_usuario'
    AND ao.fechaOperacion BETWEEN '2025-01-01' AND '2025-12-31'

ORDER BY fecha DESC;

-- 8. Ver resumen de actividad por usuario
SELECT 
    aa.userName,
    COUNT(aa.idAuditoria) as total_accesos,
    COUNT(CASE WHEN aa.codigoRespuesta >= 400 THEN 1 END) as accesos_fallidos,
    MIN(aa.fechaAcceso) as primer_acceso,
    MAX(aa.fechaAcceso) as ultimo_acceso
FROM auditoria_accesos aa
GROUP BY aa.userName
ORDER BY total_accesos DESC;

-- 9. Ver operaciones CRUD por tabla
SELECT 
    ao.tablaAfectada,
    ao.operacion,
    COUNT(*) as cantidad
FROM auditoria_operaciones ao
GROUP BY ao.tablaAfectada, ao.operacion
ORDER BY ao.tablaAfectada, ao.operacion;

-- 10. Ver sesiones expiradas o cerradas
SELECT 
    s.sessionID,
    s.userName,
    s.fechaInicio,
    s.fechaFin,
    s.estado,
    DATEDIFF(MINUTE, s.fechaInicio, ISNULL(s.fechaFin, GETDATE())) as duracion_minutos
FROM sesiones s
WHERE s.estado IN ('CERRADA', 'EXPIRADA')
ORDER BY s.fechaInicio DESC;

-- 11. Ver accesos por IP (para detectar actividad sospechosa)
SELECT 
    aa.ipAddress,
    COUNT(*) as total_accesos,
    COUNT(DISTINCT aa.userName) as usuarios_unicos,
    MIN(aa.fechaAcceso) as primer_acceso,
    MAX(aa.fechaAcceso) as ultimo_acceso
FROM auditoria_accesos aa
GROUP BY aa.ipAddress
HAVING COUNT(*) > 10  -- Solo IPs con más de 10 accesos
ORDER BY total_accesos DESC;

-- 12. Ver cambios específicos en reservas
SELECT 
    ao.userName,
    ao.operacion,
    ao.registroId,
    ao.valoresAnteriores,
    ao.valoresNuevos,
    ao.fechaOperacion
FROM auditoria_operaciones ao
WHERE ao.tablaAfectada = 'reserva'
    AND ao.operacion = 'UPDATE'
ORDER BY ao.fechaOperacion DESC;

-- 13. Ver actividad por hora del día
SELECT 
    DATEPART(HOUR, aa.fechaAcceso) as hora,
    COUNT(*) as accesos
FROM auditoria_accesos aa
GROUP BY DATEPART(HOUR, aa.fechaAcceso)
ORDER BY hora;

-- 14. Ver endpoints más accedidos
SELECT 
    aa.endpoint,
    aa.metodo,
    COUNT(*) as accesos,
    COUNT(DISTINCT aa.userName) as usuarios_unicos
FROM auditoria_accesos aa
GROUP BY aa.endpoint, aa.metodo
ORDER BY accesos DESC;

-- 15. Ver usuarios con más actividad
SELECT 
    aa.userName,
    COUNT(aa.idAuditoria) as total_accesos,
    COUNT(DISTINCT aa.endpoint) as endpoints_unicos,
    MAX(aa.fechaAcceso) as ultimo_acceso
FROM auditoria_accesos aa
GROUP BY aa.userName
ORDER BY total_accesos DESC;