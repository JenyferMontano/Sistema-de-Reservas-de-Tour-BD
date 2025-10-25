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

    if exists (select * from inserted) and exists (select * from deleted)
        set @operacion = 'UPDATE'
    else
        set @operacion = 'INSERT'

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

        insert into auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        values (@userName, 'usuario', @operacion, 0, @valoresAnteriores, @valoresNuevos, @ipAddress)
        
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
        
        alter table auditoria_operaciones nocheck constraint FK_auditoria_operaciones_usuario
        
        insert into auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        values (@userName, 'usuario', 'DELETE', 0, @valoresAnteriores, null, @ipAddress)
        
        alter table auditoria_operaciones check constraint FK_auditoria_operaciones_usuario
        
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
    declare @userName nvarchar(25)
    declare @valoresNuevos nvarchar(max)
    declare @ipAddress nvarchar(45) = '127.0.0.1'

    declare insert_cursor cursor for
    select f.idFactura, u.userName
    from inserted f
    inner join reserva r on f.reserva = r.numReserva
    inner join usuario u on r.usuario = u.userName

    open insert_cursor
    fetch next from insert_cursor into @registroId, @userName

    while @@fetch_status = 0
    begin
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

        insert into auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        values (@userName, 'factura', 'INSERT', @registroId, 'REGISTRO_NUEVO', @valoresNuevos, @ipAddress)

        fetch next from insert_cursor into @registroId, @userName
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
    declare @userName nvarchar(25)
    declare @valoresNuevos nvarchar(max)
    declare @ipAddress nvarchar(45) = '127.0.0.1'

    declare insert_cursor cursor for
    select numReserva, usuario from inserted

    open insert_cursor
    fetch next from insert_cursor into @registroId, @userName

    while @@fetch_status = 0
    begin
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

        insert into auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
        values (@userName, 'reserva', 'INSERT', @registroId, 'REGISTRO_NUEVO', @valoresNuevos, @ipAddress)

        fetch next from insert_cursor into @registroId, @userName
    end

    close insert_cursor
    deallocate insert_cursor
end
go