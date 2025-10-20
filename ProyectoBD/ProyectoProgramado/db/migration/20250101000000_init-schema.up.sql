
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
