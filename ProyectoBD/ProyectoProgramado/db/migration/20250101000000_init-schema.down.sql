
-- Eliminar tablas de auditoría
DROP TABLE IF EXISTS sesiones;
DROP TABLE IF EXISTS auditoria_accesos;
DROP TABLE IF EXISTS auditoria_operaciones;
DROP TABLE IF EXISTS auditoria_sesiones;

-- Eliminar tablas principales
DROP TABLE detallereserva;
DROP TABLE reserva;
DROP TABLE usuario;
DROP TABLE detallefactura;
DROP TABLE tour;
DROP TABLE factura;
DROP TABLE persona;
DROP DATABASE reservas_tour;

