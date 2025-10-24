USE [reservas_tour];
GO

-- =============================================
-- TABLAS DE AUDITORÍA Y CONFIGURACIÓN
-- =============================================

-- Auditoría de operaciones DBA (respaldo, restauración, listar)
IF OBJECT_ID('dbo.auditoria_dba', 'U') IS NOT NULL
    DROP TABLE dbo.auditoria_dba;
GO

CREATE TABLE auditoria_dba (
    idAuditoriaDBA INT IDENTITY(1,1) PRIMARY KEY,
    usuario_ejecutor NVARCHAR(50) NOT NULL,          
    tipo_operacion NVARCHAR(20) NOT NULL,            
    archivo_respaldo NVARCHAR(500) NULL,             
    descripcion NVARCHAR(MAX) NULL,                  
    resultado NVARCHAR(10) NOT NULL,                 
    mensaje NVARCHAR(MAX) NULL,                      
    tamaño_archivo BIGINT NULL,                      
    fecha_operacion DATETIME NOT NULL DEFAULT GETDATE(),
    ip_address NVARCHAR(45) NOT NULL,                
    user_agent NVARCHAR(500) NULL,                   
    tiempo_ejecucion_ms INT NULL,                    
    CONSTRAINT CK_auditoria_dba_tipo_operacion 
        CHECK (tipo_operacion IN ('RESPALDO', 'RESTAURAR', 'LISTAR_RESPALDOS'))
);
GO

CREATE INDEX IX_auditoria_dba_usuario_ejecutor ON auditoria_dba(usuario_ejecutor);
CREATE INDEX IX_auditoria_dba_tipo_operacion ON auditoria_dba(tipo_operacion);
CREATE INDEX IX_auditoria_dba_fecha_operacion ON auditoria_dba(fecha_operacion);
CREATE INDEX IX_auditoria_dba_resultado ON auditoria_dba(resultado);
GO

-- Historial de respaldos
IF OBJECT_ID('dbo.historial_respaldos', 'U') IS NOT NULL
    DROP TABLE dbo.historial_respaldos;
GO

CREATE TABLE historial_respaldos (
    idHistorial INT IDENTITY(1,1) PRIMARY KEY,
    archivo_respaldo NVARCHAR(500) NOT NULL,          
    ruta_completa NVARCHAR(1000) NOT NULL,           
    tamaño_archivo BIGINT NOT NULL,                  
    fecha_creacion DATETIME NOT NULL,                
    fecha_modificacion DATETIME NOT NULL,            
    usuario_creador NVARCHAR(50) NOT NULL,          
    descripcion NVARCHAR(MAX) NULL,                  
    estado NVARCHAR(20) NOT NULL DEFAULT 'ACTIVO',   
    hash_archivo NVARCHAR(128) NULL,                 
    CONSTRAINT CK_historial_respaldos_estado CHECK (estado IN ('ACTIVO', 'CORRUPTO'))
);
GO

CREATE INDEX IX_historial_respaldos_archivo ON historial_respaldos(archivo_respaldo);
CREATE INDEX IX_historial_respaldos_fecha_creacion ON historial_respaldos(fecha_creacion);
CREATE INDEX IX_historial_respaldos_estado ON historial_respaldos(estado);
CREATE INDEX IX_historial_respaldos_usuario_creador ON historial_respaldos(usuario_creador);
GO

-- Configuración de respaldos
IF OBJECT_ID('dbo.configuracion_respaldos', 'U') IS NOT NULL
    DROP TABLE dbo.configuracion_respaldos;
GO

CREATE TABLE configuracion_respaldos (
    idConfiguracion INT IDENTITY(1,1) PRIMARY KEY,
    nombre_configuracion NVARCHAR(100) NOT NULL,     
    ruta_base_respaldos NVARCHAR(1000) NOT NULL,    
    compresion BIT NOT NULL DEFAULT 1,              
    verificacion_integridad BIT NOT NULL DEFAULT 1, 
    retencion_dias INT NOT NULL DEFAULT 30,         
    hora_respaldo_automatico TIME NULL,             
    activo BIT NOT NULL DEFAULT 1,                  
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_creador NVARCHAR(50) NOT NULL,         
    fecha_modificacion DATETIME NOT NULL DEFAULT GETDATE(),
    usuario_modificador NVARCHAR(50) NULL,         
    CONSTRAINT UQ_configuracion_respaldos_nombre UNIQUE (nombre_configuracion)
);
GO

-- Configuración por defecto
INSERT INTO configuracion_respaldos (
    nombre_configuracion,
    ruta_base_respaldos,
    compresion,
    verificacion_integridad,
    retencion_dias,
    activo,
    usuario_creador
) VALUES (
    'Configuracion_Default',
    'C:\Backups\reservas_tour',
    1, -- Compresión
    1, -- Verificación
    30, -- Retención
    1, -- Activa
    'admin'
);
GO

-- =============================================
-- VISTAS DE REPORTE
-- =============================================

-- Vista auditoría DBA
CREATE VIEW v_reporte_auditoria_dba AS
SELECT 
    ad.idAuditoriaDBA,
    ad.usuario_ejecutor,
    ad.tipo_operacion,
    ad.archivo_respaldo,
    ad.descripcion,
    ad.resultado,
    ad.mensaje,
    CASE 
        WHEN ad.tamaño_archivo IS NOT NULL 
        THEN CAST(ad.tamaño_archivo / 1024.0 / 1024.0 AS DECIMAL(10,2))
        ELSE NULL 
    END AS tamaño_mb,
    ad.fecha_operacion,
    ad.ip_address,
    ad.user_agent,
    ad.tiempo_ejecucion_ms,
    DATEDIFF(MINUTE, ad.fecha_operacion, GETDATE()) AS minutos_desde_operacion
FROM auditoria_dba ad
GO

-- Vista historial de respaldos
IF OBJECT_ID('dbo.v_reporte_historial_respaldos', 'V') IS NOT NULL
    DROP VIEW dbo.v_reporte_historial_respaldos;
GO
CREATE VIEW v_reporte_historial_respaldos AS
SELECT 
    hr.idHistorial,
    hr.archivo_respaldo,
    hr.ruta_completa,
    CAST(hr.tamaño_archivo / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS tamaño_mb,
    hr.fecha_creacion,
    hr.fecha_modificacion,
    hr.usuario_creador,
    hr.descripcion,
    hr.estado,
    hr.hash_archivo,
    DATEDIFF(DAY, hr.fecha_creacion, GETDATE()) AS dias_desde_creacion
FROM historial_respaldos hr
GO

-- =============================================
-- PROCEDIMIENTOS DE MANTENIMIENTO
-- =============================================

-- Limpiar auditoría antigua
IF OBJECT_ID('dbo.sp_limpiar_auditoria_dba_antigua', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_limpiar_auditoria_dba_antigua;
GO
CREATE  PROCEDURE sp_limpiar_auditoria_dba_antigua
    @dias_retener INT = 90
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @fecha_limite DATETIME;
    SET @fecha_limite = DATEADD(DAY, -@dias_retener, GETDATE());
    
    DELETE FROM auditoria_dba 
    WHERE fecha_operacion < @fecha_limite;
    
    SELECT 
        @@ROWCOUNT AS registros_eliminados,
        @fecha_limite AS fecha_limite,
        GETDATE() AS fecha_limpieza;
END;
GO
