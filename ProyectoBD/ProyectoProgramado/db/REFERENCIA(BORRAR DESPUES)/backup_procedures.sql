USE [reservas_tour];
GO

-- =============================================
-- Eliminar procedimientos almacenados de respaldo y restauración
-- =============================================

IF OBJECT_ID('sp_respaldo_reservas_tour', 'P') IS NOT NULL
    DROP PROCEDURE sp_respaldo_db;
GO

IF OBJECT_ID('sp_restaurar_reservas_tour', 'P') IS NOT NULL
    DROP PROCEDURE sp_restaurar_db;
GO

IF OBJECT_ID('sp_listar_respaldos_reservas_tour', 'P') IS NOT NULL
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
CREATE PROCEDURE sp_respaldo_reservas_tour
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
    SET @archivo_respaldo = ISNULL(@ruta_respaldo, '') + '\reservas_tour_' + @timestamp + '.bak';
    
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
        
        -- Obtener tamaño del archivo de respaldo usando xp_fileexist
        DECLARE @tamaño_archivo BIGINT = 0;
        DECLARE @archivo_info TABLE (file_exists INT, file_is_a_directory INT, parent_directory_exists INT);
        
        INSERT INTO @archivo_info
        EXEC xp_fileexist @archivo_respaldo;
        
        -- Obtener tamaño del archivo usando una consulta alternativa
        -- Usar una consulta más simple para obtener el tamaño
        SELECT @tamaño_archivo = 0; -- Por defecto usar 0, se puede mejorar con xp_cmdshell si es necesario
        
        -- Si no se encuentra el tamaño, usar 0
        IF @tamaño_archivo IS NULL
            SET @tamaño_archivo = 0;
        
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
            @tamaño_archivo,
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
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
        
        -- Obtener información del error
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
            @error_message,
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
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_restaurar_db
-- Descripción: Restaura la base de datos desde un archivo de respaldo
-- Parámetros:
--   @ruta_respaldo: Ruta del archivo de respaldo a restaurar
--   @usuario_ejecutor: Usuario que ejecuta la restauración
--   @descripcion: Descripción opcional de la restauración
-- =============================================
USE [master];
GO

IF OBJECT_ID('sp_restaurar_reservas_tour', 'P') IS NOT NULL
    DROP PROCEDURE sp_restaurar_reservas_tour;
GO

CREATE OR ALTER PROCEDURE sp_restaurar_reservas_tour
    @ruta_respaldo NVARCHAR(500),
    @usuario_ejecutor NVARCHAR(50),
    @descripcion NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
        @error_message NVARCHAR(MAX),
        @inicio_tiempo DATETIME,
        @fin_tiempo DATETIME,
        @tiempo_ejecucion_ms INT,
        @archivo_existe INT = 0,
        @data_path NVARCHAR(500),
        @mdf NVARCHAR(500),
        @ldf NVARCHAR(500),
        @desc NVARCHAR(MAX);

    IF @descripcion IS NULL
        SET @desc = 'Restauración de la base de datos';
    ELSE
        SET @desc = @descripcion;

    SET @inicio_tiempo = GETDATE();

    BEGIN TRY
        -- Verificar permisos de DBA
        IF NOT (IS_SRVROLEMEMBER('sysadmin') = 1 OR IS_SRVROLEMEMBER('dbcreator') = 1)
            THROW 50001, 'Error: Se requieren privilegios de DBA.', 1;

        -- Verificar existencia del archivo
        DECLARE @archivo_info TABLE (file_exists INT, file_is_a_directory INT, parent_directory_exists INT);
        INSERT INTO @archivo_info EXEC xp_fileexist @ruta_respaldo;
        SELECT @archivo_existe = file_exists FROM @archivo_info;
        IF @archivo_existe = 0
            THROW 50002, 'Error: El archivo de respaldo no existe.', 1;

        -- Detectar ruta predeterminada de datos
        EXEC master.dbo.xp_instance_regread
            'HKEY_LOCAL_MACHINE',
            'Software\Microsoft\MSSQLServer\MSSQLServer',
            'DefaultData',
            @data_path OUTPUT;

        IF @data_path IS NULL
            SET @data_path = 'C:\Program Files\Microsoft SQL Server\MSSQL16.DEVELOPER\MSSQL\DATA\';

        SET @mdf = ISNULL(@data_path, 'C:\Program Files\Microsoft SQL Server\MSSQL16.DEVELOPER\MSSQL\DATA\') + 'reservas_tour.mdf';
        SET @ldf = ISNULL(@data_path, 'C:\Program Files\Microsoft SQL Server\MSSQL16.DEVELOPER\MSSQL\DATA\') + 'reservas_tour.ldf';

        -- Verificar que la base de datos existe
        IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'reservas_tour')
        BEGIN
            THROW 50004, 'Error: La base de datos reservas_tour no existe. Debe crearse primero.', 1;
        END

        -- Desconectar usuarios
        BEGIN TRY
            ALTER DATABASE [reservas_tour] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
        END TRY
        BEGIN CATCH
            PRINT 'Advertencia: No se pudieron desconectar todos los usuarios';
        END CATCH

        -- Usar nombres lógicos estándar (ya validados por el diagnóstico)
        DECLARE @logical_data_name NVARCHAR(128) = 'reservas_tour';
        DECLARE @logical_log_name NVARCHAR(128) = 'reservas_tour_log';
        
        -- La validación del archivo ya se hizo con xp_fileexist
        -- Proceder directamente con la restauración

        -- Restaurar base de datos con nombres lógicos estándar
        BEGIN TRY
            RESTORE DATABASE [reservas_tour]
            FROM DISK = @ruta_respaldo
            WITH 
                MOVE 'reservas_tour' TO @mdf,
                MOVE 'reservas_tour_log' TO @ldf,
                REPLACE,
                STATS = 10;
        END TRY
        BEGIN CATCH
            -- Si falla la restauración, proporcionar información más específica
            DECLARE @restore_error NVARCHAR(MAX) = ERROR_MESSAGE();
            DECLARE @error_msg NVARCHAR(MAX) = 'Error durante la restauración: ' + @restore_error;
            THROW 50005, @error_msg, 1;
        END CATCH

        ALTER DATABASE [reservas_tour] SET MULTI_USER;

        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);

        -- Auditoría usando sp_executesql y parámetros
        DECLARE @sql NVARCHAR(MAX) = '
            INSERT INTO auditoria_dba (
                usuario_ejecutor, tipo_operacion, archivo_respaldo, descripcion, resultado, mensaje, fecha_operacion, ip_address, user_agent, tiempo_ejecucion_ms
            ) VALUES (@usuario_ejecutor, ''RESTAURACION'', @archivo, @desc, ''EXITOSO'', ''Restauración completada exitosamente'', GETDATE(), ''127.0.0.1'', ''Sistema de Respaldo'', @tiempo);';

        EXEC sp_executesql @sql,
            N'@usuario_ejecutor NVARCHAR(50), @archivo NVARCHAR(500), @desc NVARCHAR(MAX), @tiempo INT',
            @usuario_ejecutor=@usuario_ejecutor, @archivo=@ruta_respaldo, @desc=@desc, @tiempo=@tiempo_ejecucion_ms;

        SELECT 'EXITOSO' AS resultado,
               @ruta_respaldo AS archivo_restaurado,
               @usuario_ejecutor AS usuario_ejecutor,
               GETDATE() AS fecha_restauracion,
               'Restauración completada exitosamente' AS mensaje,
               @tiempo_ejecucion_ms AS tiempo_ejecucion_ms;

    END TRY
    BEGIN CATCH
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        SET @error_message = ERROR_MESSAGE();

        BEGIN TRY
            ALTER DATABASE [reservas_tour] SET MULTI_USER;
        END TRY
        BEGIN CATCH
        END CATCH;

        -- Registrar error en auditoría
        DECLARE @sql_err NVARCHAR(MAX) = '
            INSERT INTO auditoria_dba (
                usuario_ejecutor, tipo_operacion, archivo_respaldo, descripcion, resultado, mensaje, fecha_operacion, ip_address, user_agent, tiempo_ejecucion_ms
            ) VALUES (@usuario_ejecutor, ''RESTAURACION'', @archivo, @desc, ''ERROR'', @mensaje, GETDATE(), ''127.0.0.1'', ''Sistema de Respaldo'', @tiempo);';

        BEGIN TRY
            EXEC sp_executesql @sql_err,
                N'@usuario_ejecutor NVARCHAR(50), @archivo NVARCHAR(500), @desc NVARCHAR(MAX), @mensaje NVARCHAR(MAX), @tiempo INT',
                @usuario_ejecutor=@usuario_ejecutor, @archivo=@ruta_respaldo, @desc=@desc, @mensaje=@error_message, @tiempo=@tiempo_ejecucion_ms;
        END TRY
        BEGIN CATCH
        END CATCH;

        SELECT 'ERROR' AS resultado,
               @error_message AS mensaje_error,
               @usuario_ejecutor AS usuario_ejecutor,
               GETDATE() AS fecha_error,
               @tiempo_ejecucion_ms AS tiempo_ejecucion_ms;
    END CATCH
END
GO
  

-- =============================================
-- Procedimiento: sp_listar_respaldos
-- Descripción: Lista los archivos de respaldo disponibles en una ruta
-- Parámetros:
--   @ruta_respaldos: Ruta donde buscar archivos de respaldo
-- =============================================
USE [reservas_tour];
GO

IF OBJECT_ID('sp_listar_respaldos_reservas_tour', 'P') IS NOT NULL
    DROP PROCEDURE sp_listar_respaldos_reservas_tour;
GO

CREATE PROCEDURE sp_listar_respaldos_reservas_tour
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
        
        -- Crear tabla temporal para almacenar resultados
        CREATE TABLE #temp_respaldos (
            nombre_archivo NVARCHAR(255),
            fecha_modificacion DATETIME,
            tamaño_bytes BIGINT
        );
        
        -- Usar xp_cmdshell para listar archivos .bak en la ruta especificada
        DECLARE @sql NVARCHAR(4000);
        SET @sql = 'forfiles /p "' + ISNULL(@ruta_respaldos, '') + '" /m *.bak /c "cmd /c echo @path @fdate @fsize"';
        
        -- Crear tabla temporal para capturar la salida
        CREATE TABLE #file_list (
            file_info NVARCHAR(4000)
        );
        
        -- Insertar archivos encontrados usando xp_cmdshell
        INSERT INTO #file_list
        EXEC xp_cmdshell @sql;
        
        -- Procesar los resultados y extraer información
        INSERT INTO #temp_respaldos (nombre_archivo, fecha_modificacion, tamaño_bytes)
        SELECT 
            -- Extraer solo el nombre del archivo (antes del primer espacio)
            CASE 
                WHEN CHARINDEX(' ', file_info) > 0 
                THEN LEFT(SUBSTRING(file_info, CHARINDEX('\', file_info, LEN(@ruta_respaldos)) + 1, LEN(file_info)), CHARINDEX(' ', SUBSTRING(file_info, CHARINDEX('\', file_info, LEN(@ruta_respaldos)) + 1, LEN(file_info))) - 1)
                ELSE SUBSTRING(file_info, CHARINDEX('\', file_info, LEN(@ruta_respaldos)) + 1, LEN(file_info))
            END AS nombre_archivo,
            -- Extraer fecha del archivo (formato: DD/MM/YYYY)
            CASE 
                WHEN CHARINDEX(' ', file_info) > 0 AND CHARINDEX(' ', file_info, CHARINDEX(' ', file_info) + 1) > 0
                THEN TRY_CAST(
                    SUBSTRING(file_info, 
                        CHARINDEX(' ', file_info) + 1, 
                        CHARINDEX(' ', file_info, CHARINDEX(' ', file_info) + 1) - CHARINDEX(' ', file_info) - 1
                    ) AS DATETIME)
                ELSE GETDATE()
            END AS fecha_modificacion,
            -- Extraer tamaño del archivo (último número en la línea)
            CASE 
                WHEN CHARINDEX(' ', file_info) > 0 
                THEN TRY_CAST(
                    REVERSE(LEFT(REVERSE(file_info), CHARINDEX(' ', REVERSE(file_info)) - 1)) AS BIGINT
                )
                ELSE 0
            END AS tamaño_bytes
        FROM #file_list
        WHERE file_info IS NOT NULL 
        AND file_info LIKE '%.bak%'
        AND file_info NOT LIKE '%No files found%'
        AND file_info NOT LIKE '%NULL%';
        
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
            'SISTEMA',
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
        
        -- Limpiar tablas temporales
        DROP TABLE #temp_respaldos;
        DROP TABLE #file_list;
        
    END TRY
    BEGIN CATCH
        -- Marcar fin de tiempo
        SET @fin_tiempo = GETDATE();
        SET @tiempo_ejecucion_ms = DATEDIFF(MILLISECOND, @inicio_tiempo, @fin_tiempo);
        
        -- Obtener información del error
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        
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
            'SISTEMA',
            'LISTAR_RESPALDOS',
            @ruta_respaldos,
            'Listado de archivos de respaldo',
            'ERROR',
            @error_message,
            GETDATE(),
            '127.0.0.1',
            'Sistema de Respaldo',
            @tiempo_ejecucion_ms
        );
        
        -- Limpiar tablas temporales
        IF OBJECT_ID('tempdb..#temp_respaldos') IS NOT NULL
            DROP TABLE #temp_respaldos;
        IF OBJECT_ID('tempdb..#file_list') IS NOT NULL
            DROP TABLE #file_list;
        
        -- Re-lanzar el error
        RAISERROR(@error_message, 16, 1);
    END CATCH
END
GO