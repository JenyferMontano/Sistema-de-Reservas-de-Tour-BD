CREATE DATABASE reservas_tour
COLLATE Modern_Spanish_CI_AI;
GO

-- Tabla persona
CREATE TABLE persona (
    idPersona INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(25) NOT NULL,
    apellido_1 NVARCHAR(25) NOT NULL,
    apellido_2 NVARCHAR(25) NOT NULL,
    fechaNac DATE NOT NULL,
    direccion NVARCHAR(45) NOT NULL,
    telefono NVARCHAR(20) NOT NULL,
    correo NVARCHAR(40) NOT NULL UNIQUE
);
GO

-- Tabla factura
CREATE TABLE factura (
    idFactura INT IDENTITY(1,1) PRIMARY KEY,
    persona INT NOT NULL,
    estadoFactura NVARCHAR(20) NOT NULL,
    fechaFactura DATE NOT NULL,
    metodoPago NVARCHAR(15) NOT NULL,
    iva FLOAT NOT NULL,
    subtotal FLOAT NOT NULL,
    total FLOAT NOT NULL,
    CONSTRAINT FK_factura_persona FOREIGN KEY (persona)
        REFERENCES persona (idPersona)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

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
GO

-- Tabla detallefactura
CREATE TABLE detallefactura (
    idDetalleFactura INT IDENTITY(1,1) PRIMARY KEY,
    tour INT NOT NULL,
    cantTour INT NOT NULL,
    factura INT NOT NULL,
    precioTour FLOAT NOT NULL,
    descuento FLOAT NULL,
    subTotal FLOAT NOT NULL,
    CONSTRAINT FK_detallefactura_factura FOREIGN KEY (factura)
        REFERENCES factura (idFactura)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_detallefactura_tour FOREIGN KEY (tour)
        REFERENCES tour (idTour)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO

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
GO

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
GO

-- Tabla detallereserva
CREATE TABLE detallereserva (
    idDetalle INT IDENTITY(1,1) PRIMARY KEY,
    reserva INT NOT NULL,
    fecha NVARCHAR(15) NOT NULL,
    hora NVARCHAR(15) NOT NULL,
    tour INT NOT NULL,
    cantPersonas INT NOT NULL,
    factura INT NULL,
    precio FLOAT NOT NULL,
    descuento FLOAT NOT NULL,
    subTotal FLOAT NOT NULL,
    CONSTRAINT FK_detallereserva_factura FOREIGN KEY (factura)
        REFERENCES factura (idFactura)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT FK_detallereserva_reserva FOREIGN KEY (reserva)
        REFERENCES reserva (numReserva)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT FK_detallereserva_tour FOREIGN KEY (tour)
        REFERENCES tour (idTour)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);
GO