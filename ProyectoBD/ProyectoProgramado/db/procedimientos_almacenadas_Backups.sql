USE [reservas_tour];
GO

-- =============================================
-- Eliminar procedimientos almacenados de respaldo y restauración
-- =============================================

IF OBJECT_ID('sp_respaldo_db', 'P') IS NOT NULL
    DROP PROCEDURE sp_respaldo_db;
GO

IF OBJECT_ID('sp_restaurar_db', 'P') IS NOT NULL
    DROP PROCEDURE sp_restaurar_db;
GO

IF OBJECT_ID('sp_listar_respaldos', 'P') IS NOT NULL
    DROP PROCEDURE sp_listar_respaldos;
GO

-- =============================================
-- Procedimientos Almacenados para Respaldo y Restauración
-- Base de Datos: reservas_tour
-- Fecha: 2025
-- =============================================

USE [reservas_tour];
GO

-- =============================================
-- Procedimiento: sp_respaldo_db
-- Descripción: Crea un respaldo completo de la base de datos
-- Parámetros:
--   @ruta_respaldo: Ruta donde guardar el archivo de respaldo
--   @usuario_ejecutor: Usuario que ejecuta el respaldo
--   @descripcion: Descripción opcional del respaldo
-- =============================================

CREATE PROCEDURE sp_respaldo_db
    @ruta_respaldo NVARCHAR(500),
    @usuario_ejecutor NVARCHAR(50),
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @resultado INT = 0;
    DECLARE @error_message NVARCHAR(MAX);
    DECLARE @archivo_respaldo NVARCHAR(500);
    DECLARE @timestamp NVARCHAR(20);
    DECLARE @inicio_tiempo DATETIME;
    DECLARE @fin_tiempo DATETIME;
    DECLARE @tiempo_ejecucion_ms INT;
    
    -- Marcar inicio de tiempo
    SET @inicio_tiempo = GETDATE();
    
    -- Generar timestamp único
    SET @timestamp = FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    
    -- Construir nombre del archivo de respaldo
    SET @archivo_respaldo = @ruta_respaldo + '\reservas_tour_' + @timestamp + '.bak';
    
    BEGIN TRY
        -- Verificar permisos de DBA
        IF NOT (IS_SRVROLEMEMBER('sysadmin') = 1 OR IS_SRVROLEMEMBER('dbcreator') = 1)
        BEGIN
            RAISERROR('Error: Se requieren permisos de DBA para ejecutar esta operación', 16, 1);
            RETURN;
        END
        
        -- Crear respaldo de la base de datos
        BACKUP DATABASE [reservas_tour] 
        TO DISK = @archivo_respaldo
        WITH 
            FORMAT,
            INIT,
            NAME = 'Respaldo Completo de reservas_tour',
            SKIP,
            NOREWIND,
            NOUNLOAD,
            STATS = 10,
            COMPRESSION;
        
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Registrar la operación en la tabla de auditoría DBA
        INSERT INTO auditoria_dba (
            usuario_ejecutor,
            tipo_operacion,
            archivo_respaldo,
            descripcion,
            resultado,
            mensaje,
            tamaño_archivo,
            fecha_operacion,
            ip_address,
            user_agent,
            tiempo_ejecucion_ms
        ) VALUES (
            @usuario_ejecutor,
            'RESPALDO',
            @archivo_respaldo,
            ISNULL(@descripcion, 'Respaldo completo de la base de datos'),
            'EXITOSO',
            'Respaldo completado exitosamente',
            (SELECT size FROM sys.dm_os_file_stats WHERE name = @archivo_respaldo),
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Registrar en el historial de respaldos
        INSERT INTO historial_respaldos (
            archivo_respaldo,
            ruta_completa,
            tamaño_archivo,
            fecha_creacion,
            fecha_modificacion,
            usuario_creador,
            descripcion,
            estado
        ) VALUES (
            @archivo_respaldo,
            @archivo_respaldo,
            (SELECT size FROM sys.dm_os_file_stats WHERE name = @archivo_respaldo),
            GETDATE(),
            GETDATE(),
            @usuario_ejecutor,
            ISNULL(@descripcion, 'Respaldo completo de la base de datos'),
            'ACTIVO'
        );
        
        -- Retornar información del respaldo creado
        SELECT 
            'EXITOSO' AS resultado,
            @archivo_respaldo AS archivo_respaldo,
            @timestamp AS timestamp,
            @usuario_ejecutor AS usuario_ejecutor,
            GETDATE() AS fecha_respaldo,
            'Respaldo completado exitosamente' AS mensaje,
            @tiempo_ejecucion_ms AS tiempo_ejecucion_ms;
        
    END TRY
    BEGIN CATCH
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Capturar y registrar el error
        SET @error_message = ERROR_MESSAGE();
        
        -- Registrar el error en la tabla de auditoría DBA
        INSERT INTO auditoria_dba (
            usuario_ejecutor,
            tipo_operacion,
            archivo_respaldo,
            descripcion,
            resultado,
            mensaje,
            fecha_operacion,
            ip_address,
            user_agent,
            tiempo_ejecucion_ms
        ) VALUES (
            @usuario_ejecutor,
            'RESPALDO',
            @archivo_respaldo,
            ISNULL(@descripcion, 'Respaldo completo de la base de datos'),
            'ERROR',
            'Error en respaldo: ' + @error_message,
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Retornar información del error
        SELECT 
            'ERROR' AS resultado,
            @error_message AS mensaje_error,
            @usuario_ejecutor AS usuario_ejecutor,
            GETDATE() AS fecha_error,
            @tiempo_ejecucion_ms AS tiempo_ejecucion_ms;
        
        SET @resultado = 1;
    END CATCH
    
    RETURN @resultado;
END;
GO

-- =============================================
-- Procedimiento: sp_restaurar_db
-- Descripción: Restaura la base de datos desde un archivo de respaldo
-- Parámetros:
--   @ruta_respaldo: Ruta del archivo de respaldo a restaurar
--   @usuario_ejecutor: Usuario que ejecuta la restauración
--   @descripcion: Descripción opcional de la restauración
-- =============================================

CREATE PROCEDURE sp_restaurar_db
 @ruta_respaldo NVARCHAR(500),
    @usuario_ejecutor NVARCHAR(50),
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @resultado INT = 0;
    DECLARE @error_message NVARCHAR(MAX);
    DECLARE @inicio_tiempo DATETIME;
    DECLARE @fin_tiempo DATETIME;
    DECLARE @tiempo_ejecucion_ms INT;
    
    -- Marcar inicio de tiempo
    SET @inicio_tiempo = GETDATE();
    
    BEGIN TRY
        -- Verificar permisos de DBA
        IF NOT (IS_SRVROLEMEMBER('sysadmin') = 1 OR IS_SRVROLEMEMBER('dbcreator') = 1)
        BEGIN
            RAISERROR('Error: Se requieren permisos de DBA para ejecutar esta operación', 16, 1);
            RETURN;
        END
        
        -- Verificar que el archivo de respaldo existe
        DECLARE @archivo_existe INT;
        EXEC xp_fileexist @ruta_respaldo, @archivo_existe OUTPUT;
        
        IF @archivo_existe = 0
        BEGIN
            RAISERROR('Error: El archivo de respaldo no existe en la ruta especificada', 16, 1);
            RETURN;
        END
        
        -- Establecer la base de datos en modo de usuario único
        ALTER DATABASE [reservas_tour] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        
        -- Restaurar la base de datos
        RESTORE DATABASE [reservas_tour] 
        FROM DISK = @ruta_respaldo
        WITH 
            REPLACE,
            NORECOVERY,
            STATS = 10;
        
        -- Restaurar el modo multi-usuario
        ALTER DATABASE [reservas_tour] SET MULTI_USER;
        
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Registrar la operación en la tabla de auditoría DBA
        INSERT INTO auditoria_dba (
            usuario_ejecutor,
            tipo_operacion,
            archivo_respaldo,
            descripcion,
            resultado,
            mensaje,
            fecha_operacion,
            ip_address,
            user_agent,
            tiempo_ejecucion_ms
        ) VALUES (
            @usuario_ejecutor,
            'RESTAURAR',
            @ruta_respaldo,
            ISNULL(@descripcion, 'Restauración completa de la base de datos'),
            'EXITOSO',
            'Restauración completada exitosamente',
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Retornar información de la restauración
        SELECT 
            'EXITOSO' AS resultado,
            @ruta_respaldo AS archivo_restaurado,
            @usuario_ejecutor AS usuario_ejecutor,
            GETDATE() AS fecha_restauracion,
            'Restauración completada exitosamente' AS mensaje,
            @tiempo_ejecucion_ms AS tiempo_ejecucion_ms;
        
    END TRY
    BEGIN CATCH
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Capturar y registrar el error
        SET @error_message = ERROR_MESSAGE();
        
        -- Intentar restaurar el modo multi-usuario en caso de error
        BEGIN TRY
            ALTER DATABASE [reservas_tour] SET MULTI_USER;
        END TRY
        BEGIN CATCH
            -- Error al restaurar multi-usuario, continuar
        END CATCH
        
        -- Registrar el error en la tabla de auditoría DBA
        INSERT INTO auditoria_dba (
            usuario_ejecutor,
            tipo_operacion,
            archivo_respaldo,
            descripcion,
            resultado,
            mensaje,
            fecha_operacion,
            ip_address,
            user_agent,
            tiempo_ejecucion_ms
        ) VALUES (
            @usuario_ejecutor,
            'RESTAURAR',
            @ruta_respaldo,
            ISNULL(@descripcion, 'Restauración completa de la base de datos'),
            'ERROR',
            'Error en restauración: ' + @error_message,
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Retornar información del error
        SELECT 
            'ERROR' AS resultado,
            @error_message AS mensaje_error,
            @usuario_ejecutor AS usuario_ejecutor,
            GETDATE() AS fecha_error,
            @tiempo_ejecucion_ms AS tiempo_ejecucion_ms;
        
        SET @resultado = 1;
    END CATCH
    
    RETURN @resultado;
END;
GO
  

-- =============================================
-- Procedimiento: sp_listar_respaldos
-- Descripción: Lista los archivos de respaldo disponibles en una ruta
-- Parámetros:
--   @ruta_respaldos: Ruta donde buscar archivos de respaldo
-- =============================================

CREATE PROCEDURE sp_listar_respaldos
 @ruta_respaldos NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @comando_sql NVARCHAR(1000);
    DECLARE @inicio_tiempo DATETIME;
    DECLARE @fin_tiempo DATETIME;
    DECLARE @tiempo_ejecucion_ms INT;
    
    -- Marcar inicio de tiempo
    SET @inicio_tiempo = GETDATE();
    
    BEGIN TRY
        -- Verificar permisos de DBA
        IF NOT (IS_SRVROLEMEMBER('sysadmin') = 1 OR IS_SRVROLEMEMBER('dbcreator') = 1)
        BEGIN
            RAISERROR('Error: Se requieren permisos de DBA para ejecutar esta operación', 16, 1);
            RETURN;
        END
        
        -- Listar archivos .bak en la ruta especificada
        SET @comando_sql = 'dir "' + @ruta_respaldos + '\*.bak" /b';
        
        -- Crear tabla temporal para almacenar resultados
        CREATE TABLE #temp_respaldos (
            nombre_archivo NVARCHAR(255),
            fecha_modificacion DATETIME,
            tamaño_bytes BIGINT
        );
        
        -- Insertar archivos encontrados
        INSERT INTO #temp_respaldos (nombre_archivo, fecha_modificacion, tamaño_bytes)
        SELECT 
            name AS nombre_archivo,
            modify_date AS fecha_modificacion,
            size AS tamaño_bytes
        FROM sys.dm_os_file_stats
        WHERE name LIKE '%.bak';
        
        -- Retornar lista de respaldos
        SELECT 
            nombre_archivo,
            fecha_modificacion,
            tamaño_bytes,
            CAST(tamaño_bytes / 1024.0 / 1024.0 AS DECIMAL(10,2)) AS tamaño_mb
        FROM #temp_respaldos
        ORDER BY fecha_modificacion DESC;
        
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Registrar la operación en la tabla de auditoría DBA
        INSERT INTO auditoria_dba (
            usuario_ejecutor,
            tipo_operacion,
            archivo_respaldo,
            descripcion,
            resultado,
            mensaje,
            fecha_operacion,
            ip_address,
            user_agent,
            tiempo_ejecucion_ms
        ) VALUES (
            'sistema',
            'LISTAR_RESPALDOS',
            @ruta_respaldos,
            'Listado de archivos de respaldo',
            'EXITOSO',
            'Listado completado exitosamente',
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Limpiar tabla temporal
        DROP TABLE #temp_respaldos;
        
    END TRY
    BEGIN CATCH
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Capturar y registrar el error
        DECLARE @error_message NVARCHAR(MAX);
        SET @error_message = ERROR_MESSAGE();
        
        -- Registrar el error en la tabla de auditoría DBA
        INSERT INTO auditoria_dba (
            usuario_ejecutor,
            tipo_operacion,
            archivo_respaldo,
            descripcion,
            resultado,
            mensaje,
            fecha_operacion,
            ip_address,
            user_agent,
            tiempo_ejecucion_ms
        ) VALUES (
            'sistema',
            'LISTAR_RESPALDOS',
            @ruta_respaldos,
            'Listado de archivos de respaldo',
            'ERROR',
            'Error al listar respaldos: ' + @error_message,
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Limpiar tabla temporal si existe
        IF OBJECT_ID('tempdb..#temp_respaldos') IS NOT NULL
            DROP TABLE #temp_respaldos;
        
        -- Re-lanzar el error
        RAISERROR(@error_message, 16, 1);
    END CATCH
END;
GO


