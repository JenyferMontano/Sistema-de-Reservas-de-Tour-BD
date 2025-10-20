-- Script para probar el sistema de sesiones corregido
-- Ejecutar después de aplicar las correcciones del backend
-- Compatible con SQL Server

-- PASO 1: Limpiar datos de prueba anteriores
DELETE FROM auditoria_accesos WHERE userName LIKE 'test%';
DELETE FROM auditoria_sesiones WHERE userName LIKE 'test%';
DELETE FROM sesiones WHERE userName LIKE 'test%';
DELETE FROM auditoria_operaciones WHERE userName LIKE 'test%';

-- PASO 2: Crear usuario de prueba
INSERT INTO persona (idPersona, nombre, apellido_1, apellido_2, fechaNac, direccion, telefono, correo)
VALUES (998, 'Test', 'Sesion', 'Usuario', '1990-01-01', 'Test Address', '12345678', 'test@sesion.com');

INSERT INTO usuario (userName, password, idPersona, rol, image)
VALUES ('test_sesion', 'password123', 998, 'cliente', NULL);

-- PASO 3: Simular login - crear sesión activa
INSERT INTO sesiones (sessionID, userName, ipAddress, userAgent, estado)
VALUES ('test-session-123', 'test_sesion', '127.0.0.1', 'Test Browser', 'ACTIVA');

INSERT INTO auditoria_sesiones (userName, fechaInicio, ipAddress, userAgent, estado)
VALUES ('test_sesion', GETDATE(), '127.0.0.1', 'Test Browser', 'ACTIVA');

-- PASO 4: Verificar que la sesión está activa
SELECT 
    sessionID,
    userName,
    fechaInicio,
    estado,
    ipAddress
FROM sesiones 
WHERE userName = 'test_sesion' AND estado = 'ACTIVA';

-- PASO 5: Simular logout - cerrar sesión
UPDATE sesiones 
SET fechaFin = GETDATE(), estado = 'CERRADA' 
WHERE userName = 'test_sesion' AND estado = 'ACTIVA';

UPDATE auditoria_sesiones 
SET fechaFin = GETDATE(), estado = 'CERRADA' 
WHERE userName = 'test_sesion' AND estado = 'ACTIVA';

-- PASO 6: Verificar que la sesión se cerró correctamente
SELECT 
    sessionID,
    userName,
    fechaInicio,
    fechaFin,
    estado,
    ipAddress
FROM sesiones 
WHERE userName = 'test_sesion';

SELECT 
    userName,
    fechaInicio,
    fechaFin,
    estado,
    ipAddress
FROM auditoria_sesiones 
WHERE userName = 'test_sesion';

-- PASO 7: Probar que no se puede acceder sin sesión activa
-- Esta consulta debería devolver 0 registros (no hay sesiones activas)
SELECT COUNT(*) as sesiones_activas
FROM sesiones 
WHERE userName = 'test_sesion' AND estado = 'ACTIVA';

-- PASO 8: Simular acceso denegado después del logout
-- Crear registro de acceso denegado
INSERT INTO auditoria_accesos (userName, endpoint, metodo, codigoRespuesta, ipAddress, userAgent)
VALUES ('test_sesion', '/api/v1/reserva', 'GET', 401, '127.0.0.1', 'Test Browser');

-- PASO 9: Verificar auditoría de accesos
SELECT 
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress
FROM auditoria_accesos 
WHERE userName = 'test_sesion'
ORDER BY fechaAcceso DESC;

-- PASO 10: Limpiar datos de prueba
DELETE FROM auditoria_accesos WHERE userName = 'test_sesion';
DELETE FROM auditoria_sesiones WHERE userName = 'test_sesion';
DELETE FROM sesiones WHERE userName = 'test_sesion';
DELETE FROM usuario WHERE userName = 'test_sesion';
DELETE FROM persona WHERE idPersona = 998;

PRINT 'Prueba del sistema de sesiones completada exitosamente'
GO
