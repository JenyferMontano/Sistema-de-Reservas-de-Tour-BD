-- Script para corregir el problema del trigger de auditoría de usuarios
-- Este script debe ejecutarse en SQL Server Management Studio
-- Compatible con SQL Server

-- PASO 1: Eliminar el trigger existente
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'tr_auditoria_usuarios')
BEGIN
    DROP TRIGGER tr_auditoria_usuarios
    PRINT 'Trigger tr_auditoria_usuarios eliminado'
END
GO

-- PASO 2: Crear el trigger corregido
CREATE TRIGGER tr_auditoria_usuarios
ON usuario
AFTER INSERT, UPDATE, DELETE
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
    ELSE IF EXISTS (SELECT * FROM inserted)
        SET @operacion = 'INSERT'
    ELSE
        SET @operacion = 'DELETE'
    
    -- Procesar registros afectados
    IF @operacion = 'INSERT' OR @operacion = 'UPDATE'
    BEGIN
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
            
            -- Insertar en auditoría (usar el mismo userName para evitar FK constraint)
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'usuario', @operacion, 0, @valoresAnteriores, @valoresNuevos, @ipAddress)
            
            FETCH NEXT FROM insert_cursor INTO @userName
        END
        
        CLOSE insert_cursor
        DEALLOCATE insert_cursor
    END
    
    -- Procesar registros eliminados - IMPORTANTE: usar INSTEAD OF para DELETE
    IF @operacion = 'DELETE'
    BEGIN
        DECLARE delete_cursor CURSOR FOR
        SELECT userName FROM deleted
        
        OPEN delete_cursor
        FETCH NEXT FROM delete_cursor INTO @userName
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @registroId = @userName
            
            -- Construir valores anteriores ANTES de eliminar
            SELECT @valoresAnteriores = 
                'userName: ' + userName + 
                ', idPersona: ' + CAST(idPersona AS NVARCHAR) + 
                ', rol: ' + rol + 
                ', image: ' + ISNULL(image, 'NULL')
            FROM deleted WHERE userName = @userName
            
            -- Insertar en auditoría ANTES de que se elimine el usuario
            -- Esto evita el error de FK constraint
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'usuario', @operacion, 0, @valoresAnteriores, NULL, @ipAddress)
            
            FETCH NEXT FROM delete_cursor INTO @userName
        END
        
        CLOSE delete_cursor
        DEALLOCATE delete_cursor
    END
END
GO

-- PASO 3: Verificar que el trigger se creó correctamente
SELECT 
    t.name as trigger_name,
    o.name as table_name
FROM sys.triggers t
INNER JOIN sys.objects o ON t.parent_id = o.object_id
WHERE t.name = 'tr_auditoria_usuarios'
GO

PRINT 'Trigger tr_auditoria_usuarios creado correctamente'
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

--RESLTADO:
Msg 547, Level 16, State 0, Procedure tr_auditoria_usuarios, Line 92 [Batch Start Line 165]
Instrucción INSERT en conflicto con la restricción FOREIGN KEY 'FK_auditoria_operaciones_usuario'. El conflicto ha aparecido en la base de datos 'reservas_tour', tabla 'dbo.usuario', column 'userName'.
Se terminó la instrucción.
