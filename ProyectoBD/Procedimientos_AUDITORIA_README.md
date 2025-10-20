IF OBJECT_ID('pa_sesion_create', 'P') IS NOT NULL
    DROP PROCEDURE pa_sesion_create;
GO
CREATE PROCEDURE pa_sesion_create
    @sessionID NVARCHAR(255),
    @userName NVARCHAR(25),
    @ipAddress NVARCHAR(45),
    @userAgent NVARCHAR(255),
    @estado NVARCHAR(20)
AS
BEGIN
    INSERT INTO sesiones (sessionID, userName, ipAddress, userAgent, estado)
    VALUES (@sessionID, @userName, @ipAddress, @userAgent, @estado);
END
GO

-- Procedimiento para validar sesión
IF OBJECT_ID('pa_sesion_validate', 'P') IS NOT NULL
    DROP PROCEDURE pa_sesion_validate;
GO
CREATE PROCEDURE pa_sesion_validate
    @sessionID NVARCHAR(255)
AS
BEGIN
    SELECT COUNT(*) as count
    FROM sesiones
    WHERE sessionID = @sessionID AND estado = 'ACTIVA';
END
GO

-- Procedimiento para cerrar sesión
IF OBJECT_ID('pa_sesion_close', 'P') IS NOT NULL
    DROP PROCEDURE pa_sesion_close;
GO
CREATE PROCEDURE pa_sesion_close
    @sessionID NVARCHAR(255),
    @fechaFin DATETIME,
    @estado NVARCHAR(20)
AS
BEGIN
    UPDATE sesiones
    SET fechaFin = @fechaFin, estado = @estado
    WHERE sessionID = @sessionID;
END
GO
