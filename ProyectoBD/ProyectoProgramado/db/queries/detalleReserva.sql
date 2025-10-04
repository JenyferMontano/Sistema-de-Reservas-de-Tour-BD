-- name: CreateDetalleReserva :execresult
INSERT INTO detallereserva (
  reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: UpdateDetalleReserva :exec
UPDATE detallereserva
SET reserva =?, fecha = ?, hora = ?, tour = ?, cantPersonas = ?, factura = ?, precio = ?, descuento = ?, subTotal = ?
WHERE idDetalle = ?;

-- name: DeleteDetalleReserva :exec
DELETE FROM detallereserva WHERE idDetalle = ?;

-- name: DeleteDetalleReservaByReserva :exec
DELETE FROM detallereserva WHERE reserva = ?;

-- name: GetDetalleReservaById :one
SELECT idDetalle, reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal
FROM detallereserva
WHERE idDetalle = ?;

-- name: GetAllDetalleReservas :many
SELECT 
  dr.idDetalle, 
  dr.fecha, 
  dr.hora, 
  dr.cantPersonas, 
  t.nombre AS nombreTour, 
  r.numReserva, 
  f.idFactura,
  dr.precio,
  dr.descuento,
  dr.subTotal
FROM  detallereserva dr
JOIN  tour t ON dr.tour = t.idTour
JOIN  reserva r ON dr.reserva = r.numReserva
LEFT JOIN  factura f ON dr.factura = f.idFactura;

-- name: GetDetalleReservaByReservaId :many
SELECT idDetalle, reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal
FROM  detallereserva
WHERE reserva = ?;

-- name: GetFacturaByDetalleReservaId :one
SELECT factura
FROM  detallereserva
WHERE idDetalle = ?;
