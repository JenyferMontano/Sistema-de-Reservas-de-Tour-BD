-- name: GetAllReservas :many
SELECT 
    r.numReserva,
    r.estadoReserva,
    r.fechaReserva,
    r.subTotal,
    r.impuesto,
    r.total,
    
    u.userName AS nombreUsuario,
    p.nombre AS nombreCliente,
    p.apellido_1,
    p.apellido_2

FROM reserva r
JOIN usuario u ON r.usuario = u.userName
JOIN persona p ON r.huesped = p.idPersona;

-- name: GetReservaById :one
SELECT 
    r.numReserva,
    r.estadoReserva,
    r.fechaReserva,
    r.subTotal,
    r.impuesto,
    r.total,
    
    u.userName AS nombreUsuario,
    p.nombre AS nombreCliente,
    p.apellido_1,
    p.apellido_2

FROM reserva r
JOIN usuario u ON r.usuario = u.userName
JOIN persona p ON r.huesped = p.idPersona
WHERE r.numReserva = ?;

-- name: CreateReserva :execresult
INSERT INTO reserva (
    usuario, huesped, estadoReserva, fechaReserva, subTotal, impuesto, total
) VALUES (?, ?, ?, ?, ?, ?, ?);

-- name: UpdateReserva :exec
UPDATE reserva
SET usuario = ?, huesped = ?, estadoReserva = ?, fechaReserva = ?, subTotal = ?, impuesto = ?, total = ?
WHERE numReserva = ?;

-- name: DeleteReserva :exec
DELETE FROM reserva
WHERE numReserva = ?;

-- name: GetReservasByUsuario :many
SELECT 
    r.numReserva,
    r.estadoReserva,
    r.fechaReserva,
    r.subTotal,
    r.impuesto,
    r.total
FROM reserva r
WHERE r.usuario = ?;

-- name: GetReservasByPersona :many
SELECT 
    r.numReserva,
    r.estadoReserva,
    r.fechaReserva,
    r.subTotal,
    r.impuesto,
    r.total,
    u.userName AS nombreUsuario,
    p.nombre AS nombreCliente,
    p.apellido_1,
    p.apellido_2
FROM reserva r
JOIN usuario u ON r.usuario = u.userName
JOIN persona p ON r.huesped = p.idPersona
WHERE r.huesped = ?;


-- name: UpdateReservaEstado :exec
UPDATE reserva
SET estadoReserva = ?
WHERE numReserva = ?;


