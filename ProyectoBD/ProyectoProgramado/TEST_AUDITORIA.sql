-- Script de Prueba para el Sistema de Auditoría
-- Ejecutar estas consultas después de hacer login/logout para verificar que funciona

-- 1. Ver todas las sesiones activas
SELECT 
    sessionID,
    userName,
    fechaInicio,
    fechaFin,
    estado,
    ipAddress
FROM sesiones 
ORDER BY fechaInicio DESC;

-- 2. Ver auditoría de sesiones
SELECT 
    idAuditoria,
    userName,
    fechaInicio,
    fechaFin,
    estado,
    ipAddress
FROM auditoria_sesiones 
ORDER BY fechaInicio DESC;

-- 3. Ver auditoría de accesos (últimos 20)
SELECT TOP 20
    idAuditoria,
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress
FROM auditoria_accesos 
ORDER BY fechaAcceso DESC;

-- 4. Ver auditoría de operaciones (últimos 20)
SELECT TOP 20
    idAuditoria,
    userName,
    tablaAfectada,
    operacion,
    registroId,
    fechaOperacion,
    ipAddress
FROM auditoria_operaciones 
ORDER BY fechaOperacion DESC;

-- 5. Verificar que el logout funciona correctamente
-- Esta consulta debe mostrar sesiones cerradas después del logout
SELECT 
    userName,
    COUNT(*) as total_sesiones,
    COUNT(CASE WHEN estado = 'ACTIVA' THEN 1 END) as sesiones_activas,
    COUNT(CASE WHEN estado = 'CERRADA' THEN 1 END) as sesiones_cerradas
FROM sesiones 
GROUP BY userName;

-- 6. Ver actividad de login/logout
SELECT 
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso
FROM auditoria_accesos 
WHERE endpoint IN ('/api/v1/login', '/api/v1/logout')
ORDER BY fechaAcceso DESC;

-- 7. Verificar que las sesiones se cierran correctamente
SELECT 
    s.userName,
    s.sessionID,
    s.estado as estado_sesion,
    ases.estado as estado_auditoria,
    s.fechaInicio,
    s.fechaFin
FROM sesiones s
LEFT JOIN auditoria_sesiones ases ON s.userName = ases.userName 
    AND ABS(DATEDIFF(SECOND, s.fechaInicio, ases.fechaInicio)) < 5
ORDER BY s.fechaInicio DESC;

-- 8. Limpiar datos de prueba (opcional)
-- DELETE FROM auditoria_accesos WHERE userName = 'test_user';
-- DELETE FROM auditoria_sesiones WHERE userName = 'test_user';
-- DELETE FROM sesiones WHERE userName = 'test_user';
