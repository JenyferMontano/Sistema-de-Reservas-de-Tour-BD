-- =============================================
-- FUNCIÓN HELPER PARA OBTENER USUARIO EJECUTOR
-- =============================================
-- Esta función obtiene el usuario que ejecutó la operación junto con:
-- - executorUserName: Usuario que ejecutó la operación
-- - sessionID: ID de la sesión activa del usuario ejecutor
-- - idAcceso: ID del último acceso del usuario ejecutor
-- 
-- Lógica:
-- 1. Primero intenta obtener el usuario de SESSION_CONTEXT (establecido desde Go)
-- 2. Si no está disponible, usa la sesión activa más reciente como fallback
-- 3. Obtiene sessionID e idAcceso relacionados con el usuario ejecutor
-- =============================================
IF OBJECT_ID('fn_get_user_executor', 'FN') IS NOT NULL
    DROP FUNCTION fn_get_user_executor;
GO

CREATE FUNCTION fn_get_user_executor()
RETURNS TABLE
AS
RETURN
(
    SELECT TOP 1
        COALESCE(ctx.executorUserName, s.userName, 'anonymous') AS executorUserName,
        s.sessionID,
        a.idAuditoria AS idAcceso
    FROM (
        -- Primero intentar obtener de SESSION_CONTEXT
        SELECT 
            CAST(SESSION_CONTEXT(N'executor_user') AS NVARCHAR(25)) AS executorUserName
    ) ctx
    OUTER APPLY (
        -- Si hay SESSION_CONTEXT, buscar sesión de ese usuario, sino la más reciente
        SELECT TOP 1 
            userName,
            sessionID
        FROM sesiones
        WHERE estado = 'ACTIVA'
            AND (ctx.executorUserName IS NULL OR userName = ctx.executorUserName)
        ORDER BY 
            CASE WHEN ctx.executorUserName IS NOT NULL AND userName = ctx.executorUserName THEN 0 ELSE 1 END,
            fechaInicio DESC
    ) s
    OUTER APPLY (
        -- Obtener el último acceso del usuario ejecutor
        SELECT TOP 1 idAuditoria
        FROM auditoria_accesos
        WHERE userName = COALESCE(ctx.executorUserName, s.userName)
        ORDER BY fechaAcceso DESC
    ) a
);
GO

-- =============================================
-- TRIGGERS DE AUDITORÍA
-- =============================================

-- Trigger para insert y update (after) usuarios
if exists (select * from sys.triggers where name = 'dis_auditoria_usuarios_Insert_Update')
    drop trigger dis_auditoria_usuarios_Insert_Update;
go

Create trigger dis_auditoria_usuarios_Insert_Update
on usuario
after insert, update
as
begin
    declare @operacion nvarchar(10)
    declare @registroId nvarchar(25)
    declare @userName nvarchar(25)
    declare @valoresAnteriores nvarchar(max)
    declare @valoresNuevos nvarchar(max)
    declare @ipAddress nvarchar(45) = '127.0.0.1'
    
    -- Variables para el usuario ejecutor y sus relaciones
    declare @userNameEjecutor nvarchar(25)
    declare @sessionID nvarchar(255)
    declare @idAcceso int

    if exists (select * from inserted) and exists (select * from deleted)
        set @operacion = 'UPDATE'
    else
        set @operacion = 'INSERT'

    -- Obtener el usuario ejecutor, sessionID e idAcceso una vez para todos los registros
    SELECT TOP 1
        @userNameEjecutor = executorUserName,
        @sessionID = sessionID,
        @idAcceso = idAcceso
    FROM fn_get_user_executor()

    declare insert_cursor cursor for
    select userName from inserted
    
    open insert_cursor
    fetch next from insert_cursor into @userName
    
    while @@fetch_status = 0
    begin
        set @registroId = @userName

        select @valoresNuevos = 
            'userName: ' + userName + 
            ', idPersona: ' + cast(idPersona as nvarchar) + 
            ', rol: ' + rol + 
            ', image: ' + isnull(image, 'NULL')
        from inserted where userName = @userName

        if @operacion = 'UPDATE'
        begin
            select @valoresAnteriores = 
                'userName: ' + userName + 
                ', idPersona: ' + cast(idPersona as nvarchar) + 
                ', rol: ' + rol + 
                ', image: ' + isnull(image, 'NULL')
            from deleted where userName = @userName
        end
        else if @operacion = 'INSERT'
        begin
            set @valoresAnteriores = 'REGISTRO_NUEVO'
        end

        -- Registrar auditoría con el usuario EJECUTOR (no el del registro afectado)
        -- Incluye sessionID e idAcceso para trazabilidad completa
        insert into auditoria_operaciones (
            userName, tablaAfectada, operacion, valoresAnteriores, valoresNuevos, 
            fechaOperacion, ipAddress, registroId, resultado,
            sessionID, idAcceso
        )
        values (
            @userNameEjecutor, 'usuario', @operacion, @valoresAnteriores, @valoresNuevos, 
            GETDATE(), @ipAddress, @registroId, 'EXITOSO',
            @sessionID, @idAcceso
        )
        
        fetch next from insert_cursor into @userName
    end
    
    close insert_cursor
    deallocate insert_cursor
end
go

-- Trigger para delete (after) Usuario
if exists (select * from sys.triggers where name = 'dis_auditoria_usuarios_delete')
    drop trigger dis_auditoria_usuarios_delete;
go

Create trigger dis_auditoria_usuarios_delete
on usuario
after delete
as
begin
    declare @userName nvarchar(25)
    declare @valoresAnteriores nvarchar(max)
    declare @ipAddress nvarchar(45) = '127.0.0.1'
    declare @userNameEjecutor nvarchar(25)
    declare @sessionID nvarchar(255)
    declare @idAcceso int
    
    -- Obtener el usuario ejecutor, sessionID e idAcceso una vez para todos los registros
    SELECT TOP 1
        @userNameEjecutor = executorUserName,
        @sessionID = sessionID,
        @idAcceso = idAcceso
    FROM fn_get_user_executor()
    
    declare delete_cursor cursor for
    select userName from deleted
    
    open delete_cursor
    fetch next from delete_cursor into @userName
    
    while @@fetch_status = 0
    begin
        
        select @valoresAnteriores = 
            'userName: ' + userName + 
            ', idPersona: ' + cast(idPersona as nvarchar) + 
            ', rol: ' + rol + 
            ', image: ' + isnull(image, 'NULL')
        from deleted where userName = @userName
        
        declare @registroId nvarchar(25)
        set @registroId = @userName

        -- Registrar auditoría con el usuario EJECUTOR (no el del registro afectado)
        -- Incluye sessionID e idAcceso para trazabilidad completa
        insert into auditoria_operaciones (
            userName, tablaAfectada, operacion, valoresAnteriores, valoresNuevos, 
            fechaOperacion, ipAddress, registroId, resultado,
            sessionID, idAcceso
        )
        values (
            @userNameEjecutor, 'usuario', 'DELETE', @valoresAnteriores, null, 
            GETDATE(), @ipAddress, @registroId, 'EXITOSO',
            @sessionID, @idAcceso
        )
        
        fetch next from delete_cursor into @userName
    end
    
    close delete_cursor
    deallocate delete_cursor
end
go



-- Trigger para auditoría de facturas 
if exists (select * from sys.triggers where name = 'dis_auditoria_facturas')
    drop trigger dis_auditoria_facturas;
go

create trigger dis_auditoria_facturas
on factura
after insert
as
begin
    declare @registroId int
    declare @registroIdStr nvarchar(255)
    declare @valoresNuevos nvarchar(max)
    declare @ipAddress nvarchar(45) = '127.0.0.1'
    declare @userNameEjecutor nvarchar(25)
    declare @sessionID nvarchar(255)
    declare @idAcceso int

    -- Obtener el usuario ejecutor, sessionID e idAcceso una vez para todos los registros
    SELECT TOP 1
        @userNameEjecutor = executorUserName,
        @sessionID = sessionID,
        @idAcceso = idAcceso
    FROM fn_get_user_executor()

    declare insert_cursor cursor for
    select idFactura from inserted

    open insert_cursor
    fetch next from insert_cursor into @registroId

    while @@fetch_status = 0
    begin
        
        set @registroIdStr = cast(@registroId as nvarchar(255))
        
        select @valoresNuevos = 
            'idFactura: ' + cast(idFactura as nvarchar) + 
            ', persona: ' + cast(persona as nvarchar) + 
            ', reserva: ' + cast(reserva as nvarchar) + 
            ', estadoFactura: ' + estadoFactura + 
            ', fechaFactura: ' + convert(nvarchar, fechaFactura, 120) + 
            ', metodoPago: ' + metodoPago + 
            ', iva: ' + cast(iva as nvarchar) + 
            ', subtotal: ' + cast(subtotal as nvarchar) + 
            ', total: ' + cast(total as nvarchar)
        from inserted where idFactura = @registroId

        -- Registrar auditoría con el usuario EJECUTOR (no el del registro afectado)
        -- Incluye sessionID e idAcceso para trazabilidad completa
        insert into auditoria_operaciones (
            userName, tablaAfectada, operacion, valoresAnteriores, valoresNuevos, 
            fechaOperacion, ipAddress, registroId, resultado,
            sessionID, idAcceso
        )
        values (
            @userNameEjecutor, 'factura', 'INSERT', 'REGISTRO_NUEVO', @valoresNuevos, 
            GETDATE(), @ipAddress, @registroIdStr, 'EXITOSO',
            @sessionID, @idAcceso
        )

        fetch next from insert_cursor into @registroId
    end

    close insert_cursor
    deallocate insert_cursor
end
go

-- Trigger para auditoría de reservas (solo INSERT)
if exists (select * from sys.triggers where name = 'dis_auditoria_reservas')
    drop trigger dis_auditoria_reservas;
go

create trigger dis_auditoria_reservas
on reserva
after insert
as
begin
    declare @registroId int
    declare @registroIdStr nvarchar(255)
    declare @valoresNuevos nvarchar(max)
    declare @ipAddress nvarchar(45) = '127.0.0.1'
    declare @userNameEjecutor nvarchar(25)
    declare @sessionID nvarchar(255)
    declare @idAcceso int

    -- Obtener el usuario ejecutor, sessionID e idAcceso una vez para todos los registros
    SELECT TOP 1
        @userNameEjecutor = executorUserName,
        @sessionID = sessionID,
        @idAcceso = idAcceso
    FROM fn_get_user_executor()

    declare insert_cursor cursor for
    select numReserva from inserted

    open insert_cursor
    fetch next from insert_cursor into @registroId

    while @@fetch_status = 0
    begin
        
        set @registroIdStr = cast(@registroId as nvarchar(255))
        
        select @valoresNuevos = 
            'numReserva: ' + cast(numReserva as nvarchar) + 
            ', usuario: ' + usuario + 
            ', huesped: ' + cast(huesped as nvarchar) + 
            ', estadoReserva: ' + estadoReserva + 
            ', fechaReserva: ' + convert(nvarchar, fechaReserva, 120) + 
            ', subTotal: ' + cast(subTotal as nvarchar) + 
            ', impuesto: ' + cast(impuesto as nvarchar) + 
            ', total: ' + cast(total as nvarchar)
        from inserted where numReserva = @registroId

        -- Registrar auditoría con el usuario EJECUTOR (no el del registro afectado)
        -- Incluye sessionID e idAcceso para trazabilidad completa
        insert into auditoria_operaciones (
            userName, tablaAfectada, operacion, valoresAnteriores, valoresNuevos, 
            fechaOperacion, ipAddress, registroId, resultado,
            sessionID, idAcceso
        )
        values (
            @userNameEjecutor, 'reserva', 'INSERT', 'REGISTRO_NUEVO', @valoresNuevos, 
            GETDATE(), @ipAddress, @registroIdStr, 'EXITOSO',
            @sessionID, @idAcceso
        )

        fetch next from insert_cursor into @registroId
    end

    close insert_cursor
    deallocate insert_cursor
end
go