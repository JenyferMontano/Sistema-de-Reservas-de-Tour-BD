-- Script para verificar que la auditoría de endpoints funciona correctamente
-- Ejecutar después de probar la aplicación

-- Ver todos los accesos registrados
SELECT TOP 20
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress
FROM auditoria_accesos 
ORDER BY fechaAcceso DESC;

-- Ver accesos por usuario
SELECT 
    userName,
    COUNT(*) as total_accesos,
    COUNT(DISTINCT endpoint) as endpoints_unicos,
    MIN(fechaAcceso) as primer_acceso,
    MAX(fechaAcceso) as ultimo_acceso
FROM auditoria_accesos 
GROUP BY userName
ORDER BY total_accesos DESC;

-- Ver endpoints más accedidos
SELECT 
    endpoint,
    metodo,
    COUNT(*) as accesos,
    COUNT(DISTINCT userName) as usuarios_unicos
FROM auditoria_accesos 
GROUP BY endpoint, metodo
ORDER BY accesos DESC;

-- Ver accesos por método HTTP
SELECT 
    metodo,
    COUNT(*) as cantidad,
    COUNT(DISTINCT userName) as usuarios_unicos
FROM auditoria_accesos 
GROUP BY metodo
ORDER BY cantidad DESC;

-- Ver accesos con códigos de error
SELECT 
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso
FROM auditoria_accesos 
WHERE codigoRespuesta >= 400
ORDER BY fechaAcceso DESC;

-- Ver actividad reciente (últimas 2 horas)
SELECT 
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso
FROM auditoria_accesos 
WHERE fechaAcceso >= DATEADD(HOUR, -2, GETDATE())
ORDER BY fechaAcceso DESC;
