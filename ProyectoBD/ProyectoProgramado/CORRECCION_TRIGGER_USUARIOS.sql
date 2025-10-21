-- Script para corregir el problema del trigger de auditoría de usuarios
-- Este script debe ejecutarse en SQL Server Management Studio
-- Compatible con SQL Server

-- PASO 1: Eliminar los triggers existentes
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_auditoria_usuarios')
BEGIN
    DROP TRIGGER tr_auditoria_usuarios
    PRINT 'Trigger tr_auditoria_usuarios eliminado'
END
GO

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_auditoria_usuarios_insert_update')
BEGIN
    DROP TRIGGER tr_auditoria_usuarios_insert_update
    PRINT 'Trigger tr_auditoria_usuarios_insert_update eliminado'
END
GO

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_auditoria_usuarios_delete')
BEGIN
    DROP TRIGGER tr_auditoria_usuarios_delete
    PRINT 'Trigger tr_auditoria_usuarios_delete eliminado'
END
GO

-- PASO 2: Crear triggers separados para cada operación

-- Trigger para INSERT y UPDATE (AFTER)
CREATE TRIGGER tr_auditoria_usuarios_insert_update
ON usuario
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @operacion NVARCHAR(10)
    DECLARE @registroId NVARCHAR(25)
    DECLARE @userName NVARCHAR(25)
    DECLARE @valoresAnteriores NVARCHAR(MAX)
    DECLARE @valoresNuevos NVARCHAR(MAX)
    DECLARE @ipAddress NVARCHAR(45) = '127.0.0.1'
    
    -- Determinar tipo de operación
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
        SET @operacion = 'UPDATE'
    ELSE
        SET @operacion = 'INSERT'
    
    -- Procesar registros afectados
    DECLARE insert_cursor CURSOR FOR
    SELECT userName FROM inserted
    
    OPEN insert_cursor
    FETCH NEXT FROM insert_cursor INTO @userName
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @registroId = @userName
        
        -- Construir valores nuevos
        SELECT @valoresNuevos = 
            'userName: ' + userName + 
            ', idPersona: ' + CAST(idPersona AS NVARCHAR) + 
            ', rol: ' + rol + 
            ', image: ' + ISNULL(image, 'NULL')
        FROM inserted WHERE userName = @userName
        
        -- Construir valores anteriores para UPDATE
        IF @operacion = 'UPDATE'
        BEGIN
            SELECT @valoresAnteriores = 
                'userName: ' + userName + 
                ', idPersona: ' + CAST(idPersona AS NVARCHAR) + 
                ', rol: ' + rol + 
                ', image: ' + ISNULL(image, 'NULL')
            FROM deleted WHERE userName = @userName
        END
        ELSE IF @operacion = 'INSERT'
        BEGIN
            SET @valoresAnteriores = 'REGISTRO_NUEVO'
        END
        
        -- Insertar en auditoría
        INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        VALUES (@userName, 'usuario', @operacion, 0, @valoresAnteriores, @valoresNuevos, @ipAddress)
        
        FETCH NEXT FROM insert_cursor INTO @userName
    END
    
    CLOSE insert_cursor
    DEALLOCATE insert_cursor
END
GO

-- Trigger para DELETE (INSTEAD OF)
CREATE TRIGGER tr_auditoria_usuarios_delete
ON usuario
INSTEAD OF DELETE
AS
BEGIN
    DECLARE @userName NVARCHAR(25)
    DECLARE @valoresAnteriores NVARCHAR(MAX)
    DECLARE @ipAddress NVARCHAR(45) = '127.0.0.1'
    
    -- Procesar registros que se van a eliminar
    DECLARE delete_cursor CURSOR FOR
    SELECT userName FROM deleted
    
    OPEN delete_cursor
    FETCH NEXT FROM delete_cursor INTO @userName
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Construir valores anteriores ANTES de eliminar (usar la tabla original, no deleted)
        SELECT @valoresAnteriores = 
            'userName: ' + userName + 
            ', idPersona: ' + CAST(idPersona AS NVARCHAR) + 
            ', rol: ' + rol + 
            ', image: ' + ISNULL(image, 'NULL')
        FROM usuario WHERE userName = @userName
        
        -- Insertar en auditoría ANTES de eliminar el usuario
        INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        VALUES (@userName, 'usuario', 'DELETE', 0, @valoresAnteriores, NULL, @ipAddress)
        
        FETCH NEXT FROM delete_cursor INTO @userName
    END
    
    CLOSE delete_cursor
    DEALLOCATE delete_cursor
    
    -- Ahora eliminar los registros
    DELETE FROM usuario WHERE userName IN (SELECT userName FROM deleted)
END
GO

-- PASO 3: Verificar que los triggers se crearon correctamente
SELECT 
    t.name as trigger_name,
    o.name as table_name
FROM sys.triggers t
INNER JOIN sys.objects o ON t.parent_id = o.object_id
WHERE t.name IN ('tr_auditoria_usuarios_insert_update', 'tr_auditoria_usuarios_delete')
GO

PRINT 'Triggers de auditoría de usuarios creados correctamente'
GO

-- PASO 4: Probar el trigger con un usuario de prueba
-- Crear usuario de prueba
INSERT INTO persona (idPersona, nombre, apellido_1, apellido_2, fechaNac, direccion, telefono, correo)
VALUES (999, 'Test', 'Usuario', 'Auditoria', '1990-01-01', 'Test Address', '12345678', 'test@auditoria.com');

INSERT INTO usuario (userName, password, idPersona, rol, image)
VALUES ('test_auditoria', 'password123', 999, 'cliente', NULL);

-- Verificar que se registró la operación INSERT
SELECT TOP 1
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria' AND operacion = 'INSERT'
ORDER BY fechaOperacion DESC;

-- Actualizar el usuario
UPDATE usuario 
SET rol = 'admin' 
WHERE userName = 'test_auditoria';

-- Verificar que se registró la operación UPDATE
SELECT TOP 1
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria' AND operacion = 'UPDATE'
ORDER BY fechaOperacion DESC;

-- Eliminar el usuario (esto debería funcionar sin error de FK)
DELETE FROM usuario WHERE userName = 'test_auditoria';
DELETE FROM persona WHERE idPersona = 999;

-- Verificar que se registró la operación DELETE
SELECT TOP 1
    userName,
    tablaAfectada,
    operacion,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion
FROM auditoria_operaciones 
WHERE userName = 'test_auditoria' AND operacion = 'DELETE'
ORDER BY fechaOperacion DESC;

PRINT 'Prueba del trigger completada exitosamente'
GO

--RESLTADO al eliminar el usuario:
Msg 547, Level 16, State 0, Procedure tr_auditoria_usuarios, Line 92 [Batch Start Line 165]
Instrucción INSERT en conflicto con la restricción FOREIGN KEY 'FK_auditoria_operaciones_usuario'. El conflicto ha aparecido en la base de datos 'reservas_tour', tabla 'dbo.usuario', column 'userName'.
Se terminó la instrucción.
