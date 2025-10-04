-- Crear factura
-- name: CreateFactura :execresult
INSERT INTO factura (persona, estadoFactura, fechaFactura, metodoPago, iva, subtotal, total)
VALUES (?, ?, ?, ?, ?, ?, ?);

-- Actualizar factura
-- name: UpdateFactura :exec
UPDATE factura
SET persona = ?, estadoFactura = ?, fechaFactura = ?, metodoPago = ?, iva = ?, subtotal = ?, total = ?
WHERE idFactura = ?;

-- Eliminar factura
-- name: DeleteFactura :exec
DELETE FROM factura WHERE idFactura = ?;

-- Obtener factura por ID
-- name: GetFacturaById :one
SELECT 
    f.idFactura,
    f.estadoFactura,
    f.fechaFactura,
    f.metodoPago,
    f.iva,
    f.subtotal,
    f.total,
    p.nombre,
    p.apellido_1,
    p.apellido_2
FROM factura f
JOIN persona p ON f.persona = p.idPersona
WHERE f.idFactura = ?;

-- Obtener todas las facturas
-- name: GetAllFacturas :many
SELECT 
    f.idFactura,
    f.estadoFactura,
    f.fechaFactura,
    f.metodoPago,
    f.iva,
    f.subtotal,
    f.total,
    p.nombre,
    p.apellido_1,
    p.apellido_2
FROM factura f
JOIN persona p ON f.persona = p.idPersona;
