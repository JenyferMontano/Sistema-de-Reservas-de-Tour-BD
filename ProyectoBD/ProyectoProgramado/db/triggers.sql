-- Triggers de Auditoría para Sistema de Reservas de Tour
-- Ejecutar después de crear las tablas

-- Trigger para auditoría de reservas
CREATE TRIGGER tr_auditoria_reservas
ON reserva
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @operacion NVARCHAR(10)
    DECLARE @registroId INT
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
        SELECT numReserva, usuario FROM inserted
        
        OPEN insert_cursor
        FETCH NEXT FROM insert_cursor INTO @registroId, @userName
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Construir valores nuevos
            SELECT @valoresNuevos = 
                'numReserva: ' + CAST(numReserva AS NVARCHAR) + 
                ', usuario: ' + usuario + 
                ', huesped: ' + CAST(huesped AS NVARCHAR) + 
                ', estadoReserva: ' + estadoReserva + 
                ', fechaReserva: ' + CONVERT(NVARCHAR, fechaReserva, 120) + 
                ', subTotal: ' + CAST(subTotal AS NVARCHAR) + 
                ', impuesto: ' + CAST(impuesto AS NVARCHAR) + 
                ', total: ' + CAST(total AS NVARCHAR)
            FROM inserted WHERE numReserva = @registroId
            
            -- Construir valores anteriores para UPDATE
            IF @operacion = 'UPDATE'
            BEGIN
                SELECT @valoresAnteriores = 
                    'numReserva: ' + CAST(numReserva AS NVARCHAR) + 
                    ', usuario: ' + usuario + 
                    ', huesped: ' + CAST(huesped AS NVARCHAR) + 
                    ', estadoReserva: ' + estadoReserva + 
                    ', fechaReserva: ' + CONVERT(NVARCHAR, fechaReserva, 120) + 
                    ', subTotal: ' + CAST(subTotal AS NVARCHAR) + 
                    ', impuesto: ' + CAST(impuesto AS NVARCHAR) + 
                    ', total: ' + CAST(total AS NVARCHAR)
                FROM deleted WHERE numReserva = @registroId
            END
            ELSE IF @operacion = 'INSERT'
            BEGIN
                SET @valoresAnteriores = 'REGISTRO_NUEVO'
            END
            
            -- Insertar en auditoría
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'reserva', @operacion, @registroId, @valoresAnteriores, @valoresNuevos, @ipAddress)
            
            FETCH NEXT FROM insert_cursor INTO @registroId, @userName
        END
        
        CLOSE insert_cursor
        DEALLOCATE insert_cursor
    END
    
    -- Procesar registros eliminados
    IF @operacion = 'DELETE'
    BEGIN
        DECLARE delete_cursor CURSOR FOR
        SELECT numReserva, usuario FROM deleted
        
        OPEN delete_cursor
        FETCH NEXT FROM delete_cursor INTO @registroId, @userName
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Construir valores anteriores
            SELECT @valoresAnteriores = 
                'numReserva: ' + CAST(numReserva AS NVARCHAR) + 
                ', usuario: ' + usuario + 
                ', huesped: ' + CAST(huesped AS NVARCHAR) + 
                ', estadoReserva: ' + estadoReserva + 
                ', fechaReserva: ' + CONVERT(NVARCHAR, fechaReserva, 120) + 
                ', subTotal: ' + CAST(subTotal AS NVARCHAR) + 
                ', impuesto: ' + CAST(impuesto AS NVARCHAR) + 
                ', total: ' + CAST(total AS NVARCHAR)
            FROM deleted WHERE numReserva = @registroId
            
            -- Insertar en auditoría
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'reserva', @operacion, @registroId, @valoresAnteriores, NULL, @ipAddress)
            
            FETCH NEXT FROM delete_cursor INTO @registroId, @userName
        END
        
        CLOSE delete_cursor
        DEALLOCATE delete_cursor
    END
END
GO

-- Trigger para auditoría de facturas
CREATE TRIGGER tr_auditoria_facturas
ON factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @operacion NVARCHAR(10)
    DECLARE @registroId INT
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
        SELECT f.idFactura, u.userName 
        FROM inserted f
        INNER JOIN reserva r ON f.reserva = r.numReserva
        INNER JOIN usuario u ON r.usuario = u.userName
        
        OPEN insert_cursor
        FETCH NEXT FROM insert_cursor INTO @registroId, @userName
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Construir valores nuevos
            SELECT @valoresNuevos = 
                'idFactura: ' + CAST(idFactura AS NVARCHAR) + 
                ', persona: ' + CAST(persona AS NVARCHAR) + 
                ', reserva: ' + CAST(reserva AS NVARCHAR) + 
                ', estadoFactura: ' + estadoFactura + 
                ', fechaFactura: ' + CONVERT(NVARCHAR, fechaFactura, 120) + 
                ', metodoPago: ' + metodoPago + 
                ', iva: ' + CAST(iva AS NVARCHAR) + 
                ', subtotal: ' + CAST(subtotal AS NVARCHAR) + 
                ', total: ' + CAST(total AS NVARCHAR)
            FROM inserted WHERE idFactura = @registroId
            
            -- Construir valores anteriores para UPDATE
            IF @operacion = 'UPDATE'
            BEGIN
                SELECT @valoresAnteriores = 
                    'idFactura: ' + CAST(idFactura AS NVARCHAR) + 
                    ', persona: ' + CAST(persona AS NVARCHAR) + 
                    ', reserva: ' + CAST(reserva AS NVARCHAR) + 
                    ', estadoFactura: ' + estadoFactura + 
                    ', fechaFactura: ' + CONVERT(NVARCHAR, fechaFactura, 120) + 
                    ', metodoPago: ' + metodoPago + 
                    ', iva: ' + CAST(iva AS NVARCHAR) + 
                    ', subtotal: ' + CAST(subtotal AS NVARCHAR) + 
                    ', total: ' + CAST(total AS NVARCHAR)
                FROM deleted WHERE idFactura = @registroId
            END
            ELSE IF @operacion = 'INSERT'
            BEGIN
                SET @valoresAnteriores = 'REGISTRO_NUEVO'
            END
            
            -- Insertar en auditoría
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'factura', @operacion, @registroId, @valoresAnteriores, @valoresNuevos, @ipAddress)
            
            FETCH NEXT FROM insert_cursor INTO @registroId, @userName
        END
        
        CLOSE insert_cursor
        DEALLOCATE insert_cursor
    END
    
    -- Procesar registros eliminados
    IF @operacion = 'DELETE'
    BEGIN
        DECLARE delete_cursor CURSOR FOR
        SELECT f.idFactura, u.userName 
        FROM deleted f
        INNER JOIN reserva r ON f.reserva = r.numReserva
        INNER JOIN usuario u ON r.usuario = u.userName
        
        OPEN delete_cursor
        FETCH NEXT FROM delete_cursor INTO @registroId, @userName
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Construir valores anteriores
            SELECT @valoresAnteriores = 
                'idFactura: ' + CAST(idFactura AS NVARCHAR) + 
                ', persona: ' + CAST(persona AS NVARCHAR) + 
                ', reserva: ' + CAST(reserva AS NVARCHAR) + 
                ', estadoFactura: ' + estadoFactura + 
                ', fechaFactura: ' + CONVERT(NVARCHAR, fechaFactura, 120) + 
                ', metodoPago: ' + metodoPago + 
                ', iva: ' + CAST(iva AS NVARCHAR) + 
                ', subtotal: ' + CAST(subtotal AS NVARCHAR) + 
                ', total: ' + CAST(total AS NVARCHAR)
            FROM deleted WHERE idFactura = @registroId
            
            -- Insertar en auditoría
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'factura', @operacion, @registroId, @valoresAnteriores, NULL, @ipAddress)
            
            FETCH NEXT FROM delete_cursor INTO @registroId, @userName
        END
        
        CLOSE delete_cursor
        DEALLOCATE delete_cursor
    END
END
GO

-- Triggers para auditoría de usuarios (separados para evitar problemas de FK)

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

-- Trigger para DELETE (AFTER) - Solución alternativa para tablas con CASCADE
CREATE TRIGGER tr_auditoria_usuarios_delete
ON usuario
AFTER DELETE
AS
BEGIN
    DECLARE @userName NVARCHAR(25)
    DECLARE @valoresAnteriores NVARCHAR(MAX)
    DECLARE @ipAddress NVARCHAR(45) = '127.0.0.1'
    
    -- Procesar registros eliminados
    DECLARE delete_cursor CURSOR FOR
    SELECT userName FROM deleted
    
    OPEN delete_cursor
    FETCH NEXT FROM delete_cursor INTO @userName
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Construir valores anteriores desde la tabla deleted
        SELECT @valoresAnteriores = 
            'userName: ' + userName + 
            ', idPersona: ' + CAST(idPersona AS NVARCHAR) + 
            ', rol: ' + rol + 
            ', image: ' + ISNULL(image, 'NULL')
        FROM deleted WHERE userName = @userName
        
        -- Deshabilitar temporalmente la foreign key constraint
        ALTER TABLE auditoria_operaciones NOCHECK CONSTRAINT FK_auditoria_operaciones_usuario
        
        -- Insertar en auditoría (usuario ya fue eliminado, pero deshabilitamos la FK)
        INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        VALUES (@userName, 'usuario', 'DELETE', 0, @valoresAnteriores, NULL, @ipAddress)
        
        -- Rehabilitar la foreign key constraint
        ALTER TABLE auditoria_operaciones CHECK CONSTRAINT FK_auditoria_operaciones_usuario
        
        FETCH NEXT FROM delete_cursor INTO @userName
    END
    
    CLOSE delete_cursor
    DEALLOCATE delete_cursor
END
GO
