-- =============================================
-- PROCEDIMIENTOS ALMACENADOS PARA AUDITORÍA Y SESIONES
-- Sistema de Reservas de Tour
-- =============================================
-- Descripción: Este archivo contiene procedimientos almacenados que reemplazan
--              las operaciones de auditoría y sesiones implementadas en Go
--              (services/audit.go y services/session.go)
--
-- Ventajas de usar SPs:
-- 1. Mejor rendimiento: Código precompilado y optimizado
-- 2. Seguridad: Lógica centralizada en la BD, menos exposición de código
-- 3. Control transaccional: Operaciones atómicas garantizadas
-- 4. Consistencia: Validaciones y reglas de negocio en un solo lugar
-- 5. Auditoría robusta: Registros más seguros y confiables
-- =============================================

USE [reservas_tour];
GO

-- =============================================
-- PROCEDIMIENTOS DE AUDITORÍA
-- =============================================

-- =============================================
-- Procedimiento: sp_log_access
-- Descripción: Registra el acceso a un endpoint en la tabla auditoria_accesos
-- Parámetros:
--   @userName: Nombre de usuario que accede (puede ser 'anonymous')
--   @endpoint: Ruta del endpoint accedido
--   @metodo: Método HTTP (GET, POST, PUT, DELETE, etc.)
--   @codigoRespuesta: Código de respuesta HTTP (200, 404, 500, etc.)
--   @ipAddress: Dirección IP del cliente
--   @userAgent: User agent del cliente (opcional)
-- =============================================
IF OBJECT_ID('sp_log_access', 'P') IS NOT NULL
    DROP PROCEDURE sp_log_access;
GO

CREATE PROCEDURE sp_log_access
    @userName NVARCHAR(25),
    @endpoint NVARCHAR(100),
    @metodo NVARCHAR(10),
    @codigoRespuesta INT,
    @ipAddress NVARCHAR(45),
    @userAgent NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL OR @endpoint IS NULL OR @metodo IS NULL 
           OR @codigoRespuesta IS NULL OR @ipAddress IS NULL
        BEGIN
            RAISERROR('Error: Todos los parámetros requeridos deben ser proporcionados', 16, 1);
            RETURN;
        END
        
        -- Validar código de respuesta HTTP (100-599)
        IF @codigoRespuesta < 100 OR @codigoRespuesta > 599
        BEGIN
            RAISERROR('Error: Código de respuesta HTTP inválido (debe estar entre 100 y 599)', 16, 1);
            RETURN;
        END
        
        -- Insertar registro de acceso
        INSERT INTO auditoria_accesos (
            userName, 
            endpoint, 
            metodo, 
            codigoRespuesta, 
            ipAddress, 
            userAgent,
            fechaAcceso
        )
        VALUES (
            ISNULL(@userName, 'anonymous'),
            @endpoint,
            @metodo,
            @codigoRespuesta,
            @ipAddress,
            @userAgent,
            GETDATE()
        );
        
        SELECT 
            'EXITOSO' AS resultado,
            SCOPE_IDENTITY() AS idAuditoria;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al registrar acceso: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_log_operation
-- Descripción: Registra una operación CRUD en la tabla auditoria_operaciones
-- Parámetros:
--   @userName: Nombre de usuario que realiza la operación
--   @tablaAfectada: Nombre de la tabla afectada
--   @operacion: Tipo de operación (INSERT, UPDATE, DELETE)
--   @registroID: ID del registro afectado (NVARCHAR(255))
--   @valoresAnteriores: JSON o texto con valores anteriores (NULL para INSERT)
--   @valoresNuevos: JSON o texto con valores nuevos (NULL para DELETE)
--   @ipAddress: Dirección IP del cliente
--   @resultado: Resultado de la operación (EXITOSO, FALLIDO, PENDIENTE) - Default: EXITOSO
--   @sessionID: ID de sesión relacionada (opcional, FK a sesiones)
--   @idAcceso: ID de acceso relacionado (opcional, FK a auditoria_accesos)
-- NOTA: sessionID e idAcceso se pueden obtener automáticamente desde las tablas relacionadas
--       usando las claves foráneas, por lo que son opcionales aquí.
-- =============================================
IF OBJECT_ID('sp_log_operation', 'P') IS NOT NULL
    DROP PROCEDURE sp_log_operation;
GO

CREATE PROCEDURE sp_log_operation
    @userName NVARCHAR(25),
    @tablaAfectada NVARCHAR(50),
    @operacion NVARCHAR(10),
    @registroID NVARCHAR(255),
    @valoresAnteriores NVARCHAR(MAX) = NULL,
    @valoresNuevos NVARCHAR(MAX) = NULL,
    @ipAddress NVARCHAR(45),
    @resultado NVARCHAR(10) = NULL,
    @sessionID NVARCHAR(255) = NULL,
    @idAcceso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL OR @tablaAfectada IS NULL 
           OR @operacion IS NULL OR @ipAddress IS NULL
        BEGIN
            RAISERROR('Error: Todos los parámetros requeridos deben ser proporcionados', 16, 1);
            RETURN;
        END
        
        -- Validar operación (INSERT, UPDATE, DELETE)
        IF @operacion NOT IN ('INSERT', 'UPDATE', 'DELETE')
        BEGIN
            RAISERROR('Error: Operación inválida. Debe ser INSERT, UPDATE o DELETE', 16, 1);
            RETURN;
        END
        
        -- Validar resultado si se proporciona
        IF @resultado IS NOT NULL AND @resultado NOT IN ('EXITOSO', 'FALLIDO', 'PENDIENTE')
        BEGIN
            RAISERROR('Error: resultado inválido. Debe ser EXITOSO, FALLIDO o PENDIENTE', 16, 1);
            RETURN;
        END
        
        -- Validaciones específicas por operación
        IF @operacion = 'INSERT' AND @valoresNuevos IS NULL
        BEGIN
            SET @valoresNuevos = 'REGISTRO_NUEVO';
        END
        
        IF @operacion = 'DELETE' AND @valoresAnteriores IS NULL
        BEGIN
            RAISERROR('Error: valoresAnteriores es requerido para operaciones DELETE', 16, 1);
            RETURN;
        END
        
        IF @operacion = 'UPDATE' AND (@valoresAnteriores IS NULL OR @valoresNuevos IS NULL)
        BEGIN
            RAISERROR('Error: valoresAnteriores y valoresNuevos son requeridos para operaciones UPDATE', 16, 1);
            RETURN;
        END
        
        -- Verificar si el usuario existe (opcional, solo si no es anonymous)
        IF @userName != 'anonymous' AND NOT EXISTS (SELECT 1 FROM usuario WHERE userName = @userName)
        BEGIN
            -- Para operaciones de usuarios eliminados, permitir pero registrar
            IF @tablaAfectada != 'usuario'
            BEGIN
                PRINT 'Advertencia: Usuario no encontrado en la base de datos';
            END
        END
        
        -- Verificar que sessionID existe en sesiones si se proporciona
        IF @sessionID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM sesiones WHERE sessionID = @sessionID)
        BEGIN
            RAISERROR('Error: sessionID proporcionado no existe en la tabla sesiones', 16, 1);
            RETURN;
        END
        
        -- Verificar que idAcceso existe en auditoria_accesos si se proporciona
        IF @idAcceso IS NOT NULL AND NOT EXISTS (SELECT 1 FROM auditoria_accesos WHERE idAuditoria = @idAcceso)
        BEGIN
            RAISERROR('Error: idAcceso proporcionado no existe en la tabla auditoria_accesos', 16, 1);
            RETURN;
        END
        
        -- Establecer resultado por defecto si no se proporciona
        IF @resultado IS NULL
        BEGIN
            SET @resultado = 'EXITOSO';
        END
        
        -- Si sessionID e idAcceso no se proporcionan, intentar obtenerlos automáticamente desde las FK
        -- sessionID: de la sesión activa más reciente del usuario
        IF @sessionID IS NULL
        BEGIN
            SELECT TOP 1 @sessionID = sessionID
            FROM sesiones
            WHERE userName = @userName AND estado = 'ACTIVA'
            ORDER BY fechaInicio DESC;
        END
        
        -- idAcceso: del último acceso del usuario
        IF @idAcceso IS NULL
        BEGIN
            SELECT TOP 1 @idAcceso = idAuditoria
            FROM auditoria_accesos
            WHERE userName = @userName
            ORDER BY fechaAcceso DESC;
        END
        
        -- Insertar registro de operación (orden según schema: userName, tablaAfectada, operacion, valoresAnteriores, valoresNuevos, fechaOperacion, ipAddress, registroId, resultado, sessionID, idAcceso)
        INSERT INTO auditoria_operaciones (
            userName,
            tablaAfectada,
            operacion,
            valoresAnteriores,
            valoresNuevos,
            fechaOperacion,
            ipAddress,
            registroId,
            resultado,
            sessionID,
            idAcceso
        )
        VALUES (
            @userName,
            @tablaAfectada,
            @operacion,
            @valoresAnteriores,
            @valoresNuevos,
            GETDATE(),
            @ipAddress,
            ISNULL(@registroID, ''),
            @resultado,
            @sessionID,
            @idAcceso
        );
        
        SELECT 
            'EXITOSO' AS resultado,
            SCOPE_IDENTITY() AS idAuditoria;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al registrar operación: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_log_session_start
-- Descripción: Registra el inicio de una sesión en auditoria_sesiones
-- Parámetros:
--   @userName: Nombre de usuario
--   @ipAddress: Dirección IP del cliente
--   @userAgent: User agent del cliente (opcional)
-- =============================================
IF OBJECT_ID('sp_log_session_start', 'P') IS NOT NULL
    DROP PROCEDURE sp_log_session_start;
GO

CREATE PROCEDURE sp_log_session_start
    @userName NVARCHAR(25),
    @ipAddress NVARCHAR(45),
    @userAgent NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL OR @ipAddress IS NULL
        BEGIN
            RAISERROR('Error: userName e ipAddress son requeridos', 16, 1);
            RETURN;
        END
        
        -- Verificar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM usuario WHERE userName = @userName)
        BEGIN
            RAISERROR('Error: Usuario no encontrado en la base de datos', 16, 1);
            RETURN;
        END
        
        -- Insertar registro de inicio de sesión
        INSERT INTO auditoria_sesiones (
            userName,
            fechaInicio,
            ipAddress,
            userAgent,
            estado
        )
        VALUES (
            @userName,
            GETDATE(),
            @ipAddress,
            @userAgent,
            'ACTIVA'
        );
        
        SELECT 
            'EXITOSO' AS resultado,
            SCOPE_IDENTITY() AS idAuditoria;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al registrar inicio de sesión: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_log_session_end
-- Descripción: Registra el fin de sesión para un usuario (cierra todas las sesiones activas)
-- Parámetros:
--   @userName: Nombre de usuario
-- =============================================
IF OBJECT_ID('sp_log_session_end', 'P') IS NOT NULL
    DROP PROCEDURE sp_log_session_end;
GO

CREATE PROCEDURE sp_log_session_end
    @userName NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL
        BEGIN
            RAISERROR('Error: userName es requerido', 16, 1);
            RETURN;
        END
        
        DECLARE @fechaFin DATETIME = GETDATE();
        DECLARE @sesionesCerradas INT = 0;
        
        -- Actualizar todas las sesiones activas del usuario
        UPDATE auditoria_sesiones
        SET fechaFin = @fechaFin,
            estado = 'CERRADA'
        WHERE userName = @userName 
          AND estado = 'ACTIVA';
        
        SET @sesionesCerradas = @@ROWCOUNT;
        
        SELECT 
            'EXITOSO' AS resultado,
            @sesionesCerradas AS sesionesCerradas,
            @fechaFin AS fechaFin;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al registrar fin de sesión: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_log_session_end_by_id
-- Descripción: Registra el fin de sesión específica identificada por sessionID
-- Parámetros:
--   @sessionID: ID de la sesión a cerrar
-- =============================================
IF OBJECT_ID('sp_log_session_end_by_id', 'P') IS NOT NULL
    DROP PROCEDURE sp_log_session_end_by_id;
GO

CREATE PROCEDURE sp_log_session_end_by_id
    @sessionID NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @sessionID IS NULL
        BEGIN
            RAISERROR('Error: sessionID es requerido', 16, 1);
            RETURN;
        END
        
        DECLARE @userName NVARCHAR(25);
        DECLARE @fechaFin DATETIME = GETDATE();
        DECLARE @sesionesCerradas INT = 0;
        
        -- Obtener el userName asociado a la sesión
        SELECT @userName = userName
        FROM sesiones
        WHERE sessionID = @sessionID AND estado = 'ACTIVA';
        
        -- Si no se encuentra sesión activa, retornar sin error (idempotente)
        IF @userName IS NULL
        BEGIN
            SELECT 
                'ADVERTENCIA' AS resultado,
                0 AS sesionesCerradas,
                'Sesión no encontrada o ya cerrada' AS mensaje;
            RETURN;
        END
        
        -- Actualizar sesiones activas en auditoria_sesiones
        UPDATE auditoria_sesiones
        SET fechaFin = @fechaFin,
            estado = 'CERRADA'
        WHERE userName = @userName 
          AND estado = 'ACTIVA';
        
        SET @sesionesCerradas = @@ROWCOUNT;
        
        SELECT 
            'EXITOSO' AS resultado,
            @sesionesCerradas AS sesionesCerradas,
            @fechaFin AS fechaFin,
            @userName AS userName;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al registrar fin de sesión por ID: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- PROCEDIMIENTOS DE SESIONES
-- =============================================

-- =============================================
-- Procedimiento: sp_create_session
-- Descripción: Crea una nueva sesión activa en la tabla sesiones
-- Parámetros:
--   @userName: Nombre de usuario
--   @ipAddress: Dirección IP del cliente
--   @userAgent: User agent del cliente (opcional)
-- Retorna: @sessionID (OUTPUT) - ID único de la sesión creada
-- =============================================
IF OBJECT_ID('sp_create_session', 'P') IS NOT NULL
    DROP PROCEDURE sp_create_session;
GO

CREATE PROCEDURE sp_create_session
    @userName NVARCHAR(25),
    @ipAddress NVARCHAR(45),
    @userAgent NVARCHAR(255) = NULL,
    @sessionID NVARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL OR @ipAddress IS NULL
        BEGIN
            RAISERROR('Error: userName e ipAddress son requeridos', 16, 1);
            RETURN;
        END
        
        -- Verificar que el usuario existe
        IF NOT EXISTS (SELECT 1 FROM usuario WHERE userName = @userName)
        BEGIN
            RAISERROR('Error: Usuario no encontrado en la base de datos', 16, 1);
            RETURN;
        END
        
        -- Generar un GUID único para la sesión
        SET @sessionID = NEWID();
        
        -- Insertar sesión
        INSERT INTO sesiones (
            sessionID,
            userName,
            fechaInicio,
            ipAddress,
            userAgent,
            estado
        )
        VALUES (
            @sessionID,
            @userName,
            GETDATE(),
            @ipAddress,
            @userAgent,
            'ACTIVA'
        );
        
        SELECT 
            'EXITOSO' AS resultado,
            @sessionID AS sessionID;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al crear sesión: %s', 16, 1, @error_message);
        SET @sessionID = NULL;
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_validate_session
-- Descripción: Valida si una sesión existe y está activa
-- Parámetros:
--   @sessionID: ID de la sesión a validar
-- Retorna: 1 si la sesión es válida y activa, 0 en caso contrario
-- =============================================
IF OBJECT_ID('sp_validate_session', 'P') IS NOT NULL
    DROP PROCEDURE sp_validate_session;
GO

CREATE PROCEDURE sp_validate_session
    @sessionID NVARCHAR(255),
    @isValid BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @sessionID IS NULL
        BEGIN
            SET @isValid = 0;
            RAISERROR('Error: sessionID es requerido', 16, 1);
            RETURN;
        END
        
        -- Verificar si la sesión existe y está activa
        DECLARE @count INT;
        SELECT @count = COUNT(*)
        FROM sesiones
        WHERE sessionID = @sessionID AND estado = 'ACTIVA';
        
        SET @isValid = CASE WHEN @count > 0 THEN 1 ELSE 0 END;
        
        SELECT 
            @isValid AS isValid,
            CASE WHEN @isValid = 1 THEN 'Sesión válida' ELSE 'Sesión inválida o expirada' END AS mensaje;
            
    END TRY
    BEGIN CATCH
        SET @isValid = 0;
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al validar sesión: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_close_session
-- Descripción: Cierra una sesión específica identificada por sessionID
-- Parámetros:
--   @sessionID: ID de la sesión a cerrar
-- =============================================
IF OBJECT_ID('sp_close_session', 'P') IS NOT NULL
    DROP PROCEDURE sp_close_session;
GO

CREATE PROCEDURE sp_close_session
    @sessionID NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @sessionID IS NULL
        BEGIN
            RAISERROR('Error: sessionID es requerido', 16, 1);
            RETURN;
        END
        
        DECLARE @fechaFin DATETIME = GETDATE();
        DECLARE @sesionesCerradas INT = 0;
        
        -- Cerrar la sesión
        UPDATE sesiones
        SET fechaFin = @fechaFin,
            estado = 'CERRADA'
        WHERE sessionID = @sessionID AND estado = 'ACTIVA';
        
        SET @sesionesCerradas = @@ROWCOUNT;
        
        -- Si no se encontró sesión activa, es idempotente (no error)
        IF @sesionesCerradas = 0
        BEGIN
            SELECT 
                'ADVERTENCIA' AS resultado,
                0 AS sesionesCerradas,
                'Sesión no encontrada o ya cerrada' AS mensaje;
            RETURN;
        END
        
        SELECT 
            'EXITOSO' AS resultado,
            @sesionesCerradas AS sesionesCerradas,
            @fechaFin AS fechaFin;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al cerrar sesión: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_close_all_user_sessions
-- Descripción: Cierra todas las sesiones activas de un usuario
-- Parámetros:
--   @userName: Nombre de usuario
-- =============================================
IF OBJECT_ID('sp_close_all_user_sessions', 'P') IS NOT NULL
    DROP PROCEDURE sp_close_all_user_sessions;
GO

CREATE PROCEDURE sp_close_all_user_sessions
    @userName NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL
        BEGIN
            RAISERROR('Error: userName es requerido', 16, 1);
            RETURN;
        END
        
        DECLARE @fechaFin DATETIME = GETDATE();
        DECLARE @sesionesCerradas INT = 0;
        
        -- Cerrar todas las sesiones activas del usuario
        UPDATE sesiones
        SET fechaFin = @fechaFin,
            estado = 'CERRADA'
        WHERE userName = @userName AND estado = 'ACTIVA';
        
        SET @sesionesCerradas = @@ROWCOUNT;
        
        SELECT 
            'EXITOSO' AS resultado,
            @sesionesCerradas AS sesionesCerradas,
            @fechaFin AS fechaFin;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al cerrar sesiones del usuario: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- Procedimiento: sp_get_active_sessions
-- Descripción: Obtiene todas las sesiones activas de un usuario
-- Parámetros:
--   @userName: Nombre de usuario
-- Retorna: Resultado con todas las sesiones activas del usuario
-- =============================================
IF OBJECT_ID('sp_get_active_sessions', 'P') IS NOT NULL
    DROP PROCEDURE sp_get_active_sessions;
GO

CREATE PROCEDURE sp_get_active_sessions
    @userName NVARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros requeridos
        IF @userName IS NULL
        BEGIN
            RAISERROR('Error: userName es requerido', 16, 1);
            RETURN;
        END
        
        -- Retornar sesiones activas
        SELECT 
            sessionID,
            userName,
            fechaInicio,
            fechaFin,
            ipAddress,
            userAgent,
            estado,
            DATEDIFF(MINUTE, fechaInicio, GETDATE()) AS minutosActiva
        FROM sesiones
        WHERE userName = @userName AND estado = 'ACTIVA'
        ORDER BY fechaInicio DESC;
        
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al obtener sesiones activas: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO



-- =============================================
-- PROCEDIMIENTO ADICIONAL: Limpieza de sesiones expiradas
-- =============================================

-- =============================================
-- Procedimiento: sp_clean_expired_sessions
-- Descripción: Marca como expiradas las sesiones activas con más de X horas
-- Parámetros:
--   @horasExpiracion: Número de horas para considerar una sesión como expirada (default: 24)
-- =============================================
IF OBJECT_ID('sp_clean_expired_sessions', 'P') IS NOT NULL
    DROP PROCEDURE sp_clean_expired_sessions;
GO

CREATE PROCEDURE sp_clean_expired_sessions
    @horasExpiracion INT = 24
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validar parámetros
        IF @horasExpiracion IS NULL OR @horasExpiracion <= 0
        BEGIN
            SET @horasExpiracion = 24; -- Default 24 horas
        END
        
        DECLARE @fechaExpiracion DATETIME = DATEADD(HOUR, -@horasExpiracion, GETDATE());
        DECLARE @sesionesExpiradas INT = 0;
        
        -- Marcar sesiones expiradas
        UPDATE sesiones
        SET fechaFin = GETDATE(),
            estado = 'EXPIRADA'
        WHERE estado = 'ACTIVA' 
          AND fechaInicio < @fechaExpiracion;
        
        SET @sesionesExpiradas = @@ROWCOUNT;
        
        -- También cerrar sesiones en auditoría
        UPDATE auditoria_sesiones
        SET fechaFin = GETDATE(),
            estado = 'EXPIRADA'
        WHERE estado = 'ACTIVA' 
          AND fechaInicio < @fechaExpiracion;
        
        SELECT 
            'EXITOSO' AS resultado,
            @sesionesExpiradas AS sesionesExpiradas,
            @fechaExpiracion AS fechaLimiteExpiracion;
            
    END TRY
    BEGIN CATCH
        DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();
        RAISERROR('Error al limpiar sesiones expiradas: %s', 16, 1, @error_message);
        RETURN;
    END CATCH
END
GO

-- =============================================
-- GRANT PERMISSIONS
-- =============================================
-- Otorgar permisos de ejecución a los roles apropiados
-- Ajustar según la configuración de seguridad de tu base de datos

-- GRANT EXECUTE ON sp_log_access TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_log_operation TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_log_session_start TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_log_session_end TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_log_session_end_by_id TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_create_session TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_validate_session TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_close_session TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_close_all_user_sessions TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_get_active_sessions TO [rol_aplicacion];
-- GRANT EXECUTE ON sp_clean_expired_sessions TO [rol_dba];

PRINT 'Procedimientos almacenados de auditoría y sesiones creados exitosamente';
GO

