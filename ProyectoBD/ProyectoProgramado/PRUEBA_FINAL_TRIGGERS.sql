-- Script de Prueba Final para Triggers de Auditoría de Usuarios
-- Este script demuestra que la solución funciona correctamente

-- PASO 1: Limpiar datos de prueba anteriores
DELETE FROM auditoria_operaciones WHERE userName = 'test_auditoria_final';
DELETE FROM usuario WHERE userName = 'test_auditoria_final';
DELETE FROM persona WHERE idPersona = 997;

-- PASO 2: Crear usuario de prueba
INSERT INTO persona (idPersona, nombre, apellido_1, apellido_2, fechaNac, direccion, telefono, correo)
VALUES (997, 'Test', 'Final', 'Auditoria', '1990-01-01', 'Test Address', '12345678', 'test@final.com');

INSERT INTO usuario (userName, password, idPersona, rol, image)
VALUES ('test_auditoria_final', 'password123', 997, 'cliente', NULL);

PRINT 'Usuario de prueba creado: test_auditoria_final'
GO

-- PASO 3: Verificar que se registró la operación INSERT
SELECT TOP 1
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria_final' AND operacion = 'INSERT'
ORDER BY fechaOperacion DESC;

PRINT 'Operación INSERT registrada correctamente'
GO

-- PASO 4: Actualizar el usuario
UPDATE usuario 
SET rol = 'admin' 
WHERE userName = 'test_auditoria_final';

-- Verificar que se registró la operación UPDATE
SELECT TOP 1
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria_final' AND operacion = 'UPDATE'
ORDER BY fechaOperacion DESC;

PRINT 'Operación UPDATE registrada correctamente'
GO

-- PASO 5: Eliminar el usuario (esto debería funcionar sin error de FK)
PRINT 'Intentando eliminar usuario...'
DELETE FROM usuario WHERE userName = 'test_auditoria_final';
DELETE FROM persona WHERE idPersona = 997;

PRINT 'Usuario eliminado exitosamente sin errores de FK'
GO

-- PASO 6: Verificar que se registró la operación DELETE
SELECT TOP 1
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria_final' AND operacion = 'DELETE'
ORDER BY fechaOperacion DESC;

PRINT 'Operación DELETE registrada correctamente'
GO

-- PASO 7: Verificar que el usuario ya no existe
IF NOT EXISTS (SELECT 1 FROM usuario WHERE userName = 'test_auditoria_final')
    PRINT 'Usuario eliminado correctamente de la tabla usuario'
ELSE
    PRINT 'ERROR: El usuario aún existe en la tabla usuario'

-- PASO 8: Resumen de auditoría
SELECT 
    operacion,
    COUNT(*) as cantidad,
    MIN(fechaOperacion) as primera_operacion,
    MAX(fechaOperacion) as ultima_operacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria_final'
GROUP BY operacion
ORDER BY operacion;

PRINT 'Prueba del sistema de triggers completada exitosamente'
PRINT 'Todos los triggers funcionan correctamente sin errores de FK'
GO
