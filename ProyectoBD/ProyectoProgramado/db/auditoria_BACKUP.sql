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

-- =============================================
-- VISTA PARA AUDITORÍA DBA
-- =============================================

-- Vista para auditoría DBA con campos calculados
IF OBJECT_ID('dbo.v_auditoria_dba', 'V') IS NOT NULL
    DROP VIEW dbo.v_auditoria_dba;
GO

CREATE VIEW v_auditoria_dba AS
SELECT 
    idAuditoriaDBA,
    usuario_ejecutor,
    tipo_operacion,
    archivo_respaldo,
    descripcion,
    resultado,
    mensaje,
    tamaño_archivo,
    CASE 
        WHEN tamaño_archivo IS NOT NULL 
        THEN CAST(tamaño_archivo / 1024.0 / 1024.0 AS DECIMAL(10,2))
        ELSE NULL 
    END AS tamaño_mb,
    fecha_operacion,
    ip_address,
    user_agent,
    tiempo_ejecucion_ms,
    DATEDIFF(MINUTE, fecha_operacion, GETDATE()) AS minutos_desde_operacion,
    DATEDIFF(HOUR, fecha_operacion, GETDATE()) AS horas_desde_operacion,
    DATEDIFF(DAY, fecha_operacion, GETDATE()) AS dias_desde_operacion
FROM auditoria_dba;
GO




