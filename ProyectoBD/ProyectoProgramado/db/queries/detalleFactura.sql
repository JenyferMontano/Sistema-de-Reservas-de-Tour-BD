-- Crear detalle factura
-- name: CreateDetalleFactura :execresult
INSERT INTO detallefactura (tour, cantTour, factura, precioTour, descuento, subTotal)
VALUES (?, ?, ?, ?, ?, ?);

-- Actualizar detalle factura
-- name: UpdateDetalleFactura :exec
UPDATE detallefactura
SET tour = ?, cantTour = ?, factura = ?, precioTour = ?, descuento = ?, subTotal = ?
WHERE idDetalleFactura = ?;

-- Eliminar detalle factura
-- name: DeleteDetalleFactura :exec
DELETE FROM detallefactura WHERE idDetalleFactura = ?;

-- Obtener detalle por ID
-- name: GetDetalleFacturaById :one
SELECT 
    df.idDetalleFactura,
    df.cantTour,
    df.precioTour,
    df.descuento,
    df.subTotal,
    t.nombre AS nombreTour,
    f.idFactura
FROM detallefactura df
JOIN tour t ON df.tour = t.idTour
JOIN factura f ON df.factura = f.idFactura
WHERE df.idDetalleFactura = ?;

-- Obtener todos los detalles de una factura
-- name: GetDetalleFacturaByFacturaId :many
SELECT 
    df.idDetalleFactura,
    df.cantTour,
    df.precioTour,
    df.descuento,
    df.subTotal,
    t.nombre AS nombreTour
FROM detallefactura df
JOIN tour t ON df.tour = t.idTour
WHERE df.factura = ?;

-- Obtener todos los detalles de todas las facturas
-- name: GetAllDetallesFactura :many
SELECT 
    df.idDetalleFactura,
    df.cantTour,
    df.precioTour,
    df.descuento,
    df.subTotal,
    t.nombre AS nombreTour,
    f.idFactura
FROM detallefactura df
JOIN tour t ON df.tour = t.idTour
JOIN factura f ON df.factura = f.idFactura;
