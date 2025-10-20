-- Script de Prueba Completo para el Sistema de Auditoría Corregido
-- Ejecutar estas consultas paso a paso para verificar que todo funciona

-- PASO 1: Limpiar datos de prueba anteriores (opcional)
-- DELETE FROM auditoria_accesos WHERE userName LIKE 'test%';
-- DELETE FROM auditoria_sesiones WHERE userName LIKE 'test%';
-- DELETE FROM sesiones WHERE userName LIKE 'test%';

-- PASO 2: Verificar que las tablas existen
SELECT 'auditoria_accesos' as tabla, COUNT(*) as registros FROM auditoria_accesos
UNION ALL
SELECT 'auditoria_sesiones' as tabla, COUNT(*) as registros FROM auditoria_sesiones
UNION ALL
SELECT 'auditoria_operaciones' as tabla, COUNT(*) as registros FROM auditoria_operaciones
UNION ALL
SELECT 'sesiones' as tabla, COUNT(*) as registros FROM sesiones;

-- PASO 3: Verificar que los triggers existen
SELECT 
    t.name as trigger_name,
    o.name as table_name
FROM sys.triggers t
INNER JOIN sys.objects o ON t.parent_id = o.object_id
WHERE t.name LIKE 'tr_auditoria_%'
ORDER BY o.name;

-- PASO 4: Probar operaciones CRUD para verificar triggers
-- (Ejecutar estas operaciones desde tu aplicación o directamente)

-- Crear un usuario de prueba
INSERT INTO persona (idPersona, nombre, apellido_1, apellido_2, fechaNac, direccion, telefono, correo)
VALUES (999, 'Test', 'Usuario', 'Auditoria', '1990-01-01', 'Test Address', '12345678', 'test@auditoria.com');

INSERT INTO usuario (userName, password, idPersona, rol, image)
VALUES ('test_auditoria', 'password123', 999, 'cliente', NULL);

-- Verificar que se registró la operación INSERT
SELECT TOP 5
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria'
ORDER BY fechaOperacion DESC;

-- Actualizar el usuario
UPDATE usuario 
SET rol = 'admin' 
WHERE userName = 'test_auditoria';

-- Verificar que se registró la operación UPDATE
SELECT TOP 5
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria'
ORDER BY fechaOperacion DESC;

-- Eliminar el usuario
DELETE FROM usuario WHERE userName = 'test_auditoria';
DELETE FROM persona WHERE idPersona = 999;

-- Verificar que se registró la operación DELETE
SELECT TOP 5
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria'
ORDER BY fechaOperacion DESC;

-- PASO 5: Verificar auditoría de accesos y sesiones
-- (Estas se generan cuando haces login/logout desde la aplicación)

-- Ver todos los accesos recientes
SELECT TOP 20
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress
FROM auditoria_accesos 
ORDER BY fechaAcceso DESC;

-- Ver todas las sesiones
SELECT 
    userName,
    fechaInicio,
    fechaFin,
    estado,
    ipAddress
FROM auditoria_sesiones 
ORDER BY fechaInicio DESC;

-- Ver sesiones activas
SELECT 
    sessionID,
    userName,
    fechaInicio,
    estado,
    ipAddress
FROM sesiones 
WHERE estado = 'ACTIVA'
ORDER BY fechaInicio DESC;

-- PASO 6: Verificar que los valores anteriores no sean NULL en INSERT
SELECT 
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE operacion = 'INSERT' 
    AND valoresAnteriores IS NULL
ORDER BY fechaOperacion DESC;

-- PASO 7: Verificar que no hay errores de FOREIGN KEY
-- Esta consulta debe devolver 0 registros si todo está bien
SELECT 
    userName,
    COUNT(*) as operaciones
FROM auditoria_operaciones 
WHERE userName NOT IN (SELECT userName FROM usuario)
GROUP BY userName;

-- PASO 8: Resumen de auditoría por tipo de operación
SELECT 
    operacion,
    COUNT(*) as cantidad,
    MIN(fechaOperacion) as primera_operacion,
    MAX(fechaOperacion) as ultima_operacion
FROM auditoria_operaciones 
GROUP BY operacion
ORDER BY operacion;

-- PASO 9: Verificar que el logout funciona correctamente
-- Después de hacer logout desde la aplicación, ejecutar:
SELECT 
    userName,
    COUNT(*) as total_sesiones,
    COUNT(CASE WHEN estado = 'ACTIVA' THEN 1 END) as sesiones_activas,
    COUNT(CASE WHEN estado = 'CERRADA' THEN 1 END) as sesiones_cerradas
FROM sesiones 
GROUP BY userName
ORDER BY userName;

-- PASO 10: Verificar auditoría de login/logout
SELECT 
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso
FROM auditoria_accesos 
WHERE endpoint IN ('/api/v1/login', '/api/v1/logout')
ORDER BY fechaAcceso DESC;

-- PASO 11: Limpiar datos de prueba (opcional)
-- DELETE FROM auditoria_accesos WHERE userName = 'test_auditoria';
-- DELETE FROM auditoria_sesiones WHERE userName = 'test_auditoria';
-- DELETE FROM auditoria_operaciones WHERE userName = 'test_auditoria';
-- DELETE FROM sesiones WHERE userName = 'test_auditoria';
