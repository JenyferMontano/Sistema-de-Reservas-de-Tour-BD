-- Script de Prueba para Sistema de Auditoría
-- Ejecutar después de crear tablas y triggers

-- Crear usuario de prueba
INSERT INTO persona (idPersona, nombre, apellido_1, apellido_2, fechaNac, direccion, telefono, correo)
VALUES (999, 'Test', 'Usuario', 'Auditoria', '1990-01-01', 'Test Address', '12345678', 'test@auditoria.com');

INSERT INTO usuario (userName, password, idPersona, rol, image)
VALUES ('test_auditoria', 'password123', 999, 'cliente', NULL);

-- Verificar INSERT
SELECT TOP 1 * FROM auditoria_operaciones 
WHERE userName = 'test_auditoria' AND operacion = 'INSERT'
ORDER BY fechaOperacion DESC;

-- Actualizar usuario
UPDATE usuario SET rol = 'admin' WHERE userName = 'test_auditoria';

-- Verificar UPDATE
SELECT TOP 1 * FROM auditoria_operaciones 
WHERE userName = 'test_auditoria' AND operacion = 'UPDATE'
ORDER BY fechaOperacion DESC;

-- Eliminar usuario
DELETE FROM usuario WHERE userName = 'test_auditoria';
DELETE FROM persona WHERE idPersona = 999;

-- Verificar DELETE
SELECT TOP 1 * FROM auditoria_operaciones 
WHERE userName = 'test_auditoria' AND operacion = 'DELETE'
ORDER BY fechaOperacion DESC;

PRINT 'Prueba de auditoría completada exitosamente';
