
-- name: GetAllFacturas :many
SELECT 
    f.idFactura,
    f.estadoFactura,
    f.fechaFactura,
    f.metodoPago,
    f.iva,
    f.subtotal,
    f.total,
    p.nombre AS nombrePersona,
    p.apellido_1,
    p.apellido_2,
    r.numReserva,
    r.estadoReserva
FROM factura f
JOIN persona p ON f.persona = p.idPersona
JOIN reserva r ON f.reserva = r.numReserva;

-- name: GetFacturaById :one
SELECT 
    f.idFactura,
    f.estadoFactura,
    f.fechaFactura,
    f.metodoPago,
    f.iva,
    f.subtotal,
    f.total,
    p.nombre AS nombrePersona,
    p.apellido_1,
    p.apellido_2,
    r.numReserva,
    r.estadoReserva
FROM factura f
JOIN persona p ON f.persona = p.idPersona
JOIN reserva r ON f.reserva = r.numReserva
WHERE f.idFactura = ?;

-- name: CreateFactura :execresult
INSERT INTO factura (
    persona, reserva, estadoFactura, fechaFactura, metodoPago, iva, subtotal, total
) VALUES (?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateFactura :exec
UPDATE factura
SET persona = ?, reserva = ?, estadoFactura = ?, fechaFactura = ?, metodoPago = ?, iva = ?, subtotal = ?, total = ?
WHERE idFactura = ?;


-- name: DeleteFactura :exec
DELETE FROM factura
WHERE idFactura = ?;

-- name: GetFacturaByReservaId :one
SELECT 
    f.idFactura,
    f.estadoFactura,
    f.fechaFactura,
    f.metodoPago,
    f.iva,
    f.subtotal,
    f.total
FROM factura f
WHERE f.reserva = ?;

-- name: GetFacturasByUsuarioId :many
SELECT 
    f.idFactura,
    f.estadoFactura,
    f.fechaFactura,
    f.metodoPago,
    f.total,
    r.numReserva,
    r.estadoReserva
FROM factura f
JOIN reserva r ON f.reserva = r.numReserva
WHERE r.usuario = ?;




