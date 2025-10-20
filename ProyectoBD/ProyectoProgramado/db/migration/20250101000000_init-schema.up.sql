
-- Tabla persona
CREATE TABLE persona (
    idPersona INT  PRIMARY KEY,
    nombre NVARCHAR(25) NOT NULL,
    apellido_1 NVARCHAR(25) NOT NULL,
    apellido_2 NVARCHAR(25) NOT NULL,
    fechaNac DATE NOT NULL,
    direccion NVARCHAR(45) NOT NULL,
    telefono NVARCHAR(20) NOT NULL,
    correo NVARCHAR(40) NOT NULL UNIQUE
);


-- Tabla tour
CREATE TABLE tour (
    idTour INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(20) NOT NULL,
    descripcion NVARCHAR(MAX) NOT NULL,
    tipo NVARCHAR(45) NOT NULL,
    disponibilidad TINYINT NOT NULL,
    precioBase FLOAT NOT NULL,
    ubicacion NVARCHAR(45) NOT NULL,
    imageTour NVARCHAR(255) NOT NULL
);


-- Tabla usuario
CREATE TABLE usuario (
    userName NVARCHAR(25) PRIMARY KEY,
    password NVARCHAR(25) NOT NULL,
    idPersona INT NOT NULL,
    rol NVARCHAR(15) NOT NULL,
    image NVARCHAR(255) NULL,
    CONSTRAINT FK_usuario_persona FOREIGN KEY (idPersona)
        REFERENCES persona (idPersona)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- Tabla reserva
CREATE TABLE reserva (
    numReserva INT IDENTITY(1,1) PRIMARY KEY,
    usuario NVARCHAR(25) NOT NULL,
    huesped INT NOT NULL,
    estadoReserva NVARCHAR(20) NOT NULL,
    fechaReserva DATETIME NOT NULL,
    subTotal FLOAT NOT NULL,
    impuesto FLOAT NOT NULL,
    total FLOAT NOT NULL,
    CONSTRAINT FK_reserva_usuario FOREIGN KEY (usuario)
        REFERENCES usuario (userName)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_reserva_huesped FOREIGN KEY (huesped)
        REFERENCES persona (idPersona)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- Tabla factura
CREATE TABLE factura (
    idFactura INT IDENTITY(1,1) PRIMARY KEY,
    persona INT NOT NULL,
    reserva INT NOT NULL,  
    estadoFactura NVARCHAR(20) NOT NULL,
    fechaFactura DATE NOT NULL,
    metodoPago NVARCHAR(15) NOT NULL,
    iva FLOAT NOT NULL,
    subtotal FLOAT NOT NULL,
    total FLOAT NOT NULL,
    CONSTRAINT FK_factura_persona FOREIGN KEY (persona)
        REFERENCES persona (idPersona)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_factura_reserva FOREIGN KEY (reserva)
        REFERENCES reserva (numReserva)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- Tabla detallereserva
CREATE TABLE detallereserva (
    idDetalle INT IDENTITY(1,1) PRIMARY KEY,
    reserva INT NOT NULL,
    fecha NVARCHAR(15) NOT NULL,
    hora NVARCHAR(15) NOT NULL,
    tour INT NOT NULL,
    cantPersonas INT NOT NULL,
    precio FLOAT NOT NULL,
    descuento FLOAT NOT NULL,
    subTotal FLOAT NOT NULL,
    CONSTRAINT FK_detallereserva_reserva FOREIGN KEY (reserva)
        REFERENCES reserva (numReserva)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_detallereserva_tour FOREIGN KEY (tour)
        REFERENCES tour (idTour)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- Tabla detallefactura
CREATE TABLE detallefactura (
    idDetalleFactura INT IDENTITY(1,1) PRIMARY KEY,
    factura INT NOT NULL,
    tour INT NOT NULL,
    cantTour INT NOT NULL,
    precioTour FLOAT NOT NULL,
    descuento FLOAT NULL,
    subTotal FLOAT NOT NULL,
    detalleReserva INT NULL,
    CONSTRAINT FK_detallefactura_factura FOREIGN KEY (factura)
        REFERENCES factura (idFactura)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_detallefactura_tour FOREIGN KEY (tour)
        REFERENCES tour (idTour)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_detallefactura_detallereserva FOREIGN KEY (detalleReserva)
        REFERENCES detallereserva (idDetalle)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


CREATE TABLE auditoria_sesiones (
    idAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    userName NVARCHAR(25) NOT NULL,
    fechaInicio DATETIME NOT NULL,
    fechaFin DATETIME NULL,
    ipAddress NVARCHAR(45) NOT NULL,
    userAgent NVARCHAR(255) NULL,
    estado NVARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT FK_auditoria_sesiones_usuario FOREIGN KEY (userName)
        REFERENCES usuario (userName)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE auditoria_operaciones (
    idAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    userName NVARCHAR(25) NOT NULL,
    tablaAfectada NVARCHAR(50) NOT NULL,
    operacion NVARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    registroId INT NOT NULL,
    valoresAnteriores NVARCHAR(MAX) NULL,
    valoresNuevos NVARCHAR(MAX) NULL,
    fechaOperacion DATETIME NOT NULL DEFAULT GETDATE(),
    ipAddress NVARCHAR(45) NOT NULL,
    CONSTRAINT FK_auditoria_operaciones_usuario FOREIGN KEY (userName)
        REFERENCES usuario (userName)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE auditoria_accesos (
    idAuditoria INT IDENTITY(1,1) PRIMARY KEY,
    userName NVARCHAR(25) NOT NULL,
    endpoint NVARCHAR(100) NOT NULL,
    metodo NVARCHAR(10) NOT NULL, -- 'GET', 'POST', 'PUT', 'DELETE'
    codigoRespuesta INT NOT NULL,
    fechaAcceso DATETIME NOT NULL DEFAULT GETDATE(),
    ipAddress NVARCHAR(45) NOT NULL,
    userAgent NVARCHAR(255) NULL,
    CONSTRAINT FK_auditoria_accesos_usuario FOREIGN KEY (userName)
        REFERENCES usuario (userName)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


CREATE TABLE sesiones (
    sessionID NVARCHAR(255) PRIMARY KEY,
    userName NVARCHAR(25) NOT NULL,
    fechaInicio DATETIME NOT NULL DEFAULT GETDATE(),
    fechaFin DATETIME NULL,
    ipAddress NVARCHAR(45) NOT NULL,
    userAgent NVARCHAR(255) NULL,
    estado NVARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
    CONSTRAINT FK_sesiones_usuario FOREIGN KEY (userName)
        REFERENCES usuario (userName)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Triggers de Auditoría

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
    DECLARE @ipAddress NVARCHAR(45) = '127.0.0.1' -- IP por defecto, se puede mejorar
    
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

-- Trigger para auditoría de usuarios
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
    
    -- Procesar registros eliminados
    IF @operacion = 'DELETE'
    BEGIN
        DECLARE delete_cursor CURSOR FOR
        SELECT userName FROM deleted
        
        OPEN delete_cursor
        FETCH NEXT FROM delete_cursor INTO @userName
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @registroId = @userName
            
            -- Construir valores anteriores
            SELECT @valoresAnteriores = 
                'userName: ' + userName + 
                ', idPersona: ' + CAST(idPersona AS NVARCHAR) + 
                ', rol: ' + rol + 
                ', image: ' + ISNULL(image, 'NULL')
            FROM deleted WHERE userName = @userName
            
            -- Para DELETE, insertar antes de que se elimine el usuario
            -- Usar el userName del registro que se va a eliminar
            INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
            VALUES (@userName, 'usuario', @operacion, 0, @valoresAnteriores, NULL, @ipAddress)
            
            FETCH NEXT FROM delete_cursor INTO @userName
        END
        
        CLOSE delete_cursor
        DEALLOCATE delete_cursor
    END
END
GO