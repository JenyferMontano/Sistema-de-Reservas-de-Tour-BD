
-- name: CreateDetalleFactura :exec
INSERT INTO detallefactura (
    factura, tour, cantTour, precioTour, descuento, subTotal, detalleReserva
) VALUES (?, ?, ?, ?, ?, ?, ?);

-- name: UpdateDetalleFactura :exec
UPDATE detallefactura
SET factura = ?, tour = ?, cantTour = ?, precioTour = ?, descuento = ?, subTotal = ?, detalleReserva = ?
WHERE idDetalleFactura = ?;

-- name: DeleteDetalleFactura :exec
DELETE FROM detallefactura
WHERE idDetalleFactura = ?;

-- name: DeleteDetalleFacturaByFacturaId :exec
DELETE FROM detallefactura
WHERE factura = ?;

-- name: GetAllDetalleFacturas :many
SELECT 
    df.idDetalleFactura,
    t.nombre AS nombreTour,
    df.cantTour,
    df.precioTour,
    df.descuento,
    df.subTotal,
    dr.fecha,
    dr.hora
FROM detallefactura df
JOIN tour t ON df.tour = t.idTour
LEFT JOIN detallereserva dr ON df.detalleReserva = dr.idDetalle
WHERE df.factura = ?;

-- name: GetDetalleFacturaById :one
SELECT 
    df.idDetalleFactura,
    df.factura,
    df.tour,
    df.cantTour,
    df.precioTour,
    df.descuento,
    df.subTotal,
    df.detalleReserva
FROM detallefactura df
WHERE df.idDetalleFactura = ?;

-- name: MigrateDetalleReservaToDetalleFactura :exec
INSERT INTO detallefactura (factura, tour, cantTour, precioTour, descuento, subTotal, detalleReserva)
SELECT 
    @idFactura,
    dr.tour,
    dr.cantPersonas,
    dr.precio,
    dr.descuento,
    dr.subTotal,
    dr.idDetalle
FROM detallereserva dr
WHERE dr.reserva = @idReserva;






