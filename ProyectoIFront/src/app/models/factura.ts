// factura.ts

/**
 * @interface FacturaBase
 * Representa la estructura de una Factura completa devuelta por GetFacturaById o GetFacturaByReserva.
 * Corresponde a GetFacturaByIdRow en Go.
 */
export interface FacturaBase {
  // Datos de la Factura
  idfactura: number; // Mapea a 'idfactura' en JSON (Idfactura en Go, pero debe ser camelCase)
  estadofactura: string;
  fechafactura: string; // Se mapea como string en JSON (Date en Go)
  metodopago: string;
  iva: number;
  subtotal: number;
  total: number; // EL TOTAL FINAL CALCULADO

  // Datos de la Persona (Cliente)
  idpersona: number;
  nombrepersona: string;
  apellido_1: string;
  apellido_2: string;

  // Datos de la Reserva
  numreserva: number;
  estadoreserva: string;
  fechareserva: string; // Fecha de la reserva
}

/**
 * @interface FacturaCreateRequest
 * Estructura de datos para crear una nueva factura (petición al POST /factura).
 * Corresponde a CreateFacturaRequest en Go Handler.
 */
export interface FacturaCreateRequest {
  persona: number;
  reserva: number;
  estadoFactura: string;
  metodoPago: string;
  iva: number;
  subtotal: number;
  // El 'total' no se envía, ya que el backend lo calcula.
}


/**
 * @interface FacturaListALL
 * Estructura de datos para listar facturas (GetAllFacturas).
 * Corresponde a GetAllFacturasRow en Go.
 */
export interface FacturaListALL {
  idfactura: number;
  estadofactura: string;
  fechafactura: string;
  metodopago: string;
  iva: number;
  subtotal: number;
  total: number;

  // Datos del Cliente
  idpersona: number;
  nombrepersona: string;
  apellido_1: string;
  apellido_2: string;

  //Datos del usuario que creó la factura
  usuario: string;

  // Datos de la Reserva
  numreserva: number;
  estadoreserva: string;
}

/**
 * @interface FacturaList
 * Estructura de datos para listar facturas (GetFacturasByUsuario).
 * Corresponde a FacturaUsuarioRows en Go.
 */
export interface FacturaList {
  idfactura: number;
  estadofactura: string;
  fechafactura: string;
  metodopago: string;
  iva: number;
  subtotal: number;
  total: number;

  // Datos del Cliente
  idpersona: number;
  nombrepersona: string;
  apellido_1: string;
  apellido_2: string;

  // Datos de la Reserva
  numreserva: number;
  estadoreserva: string;
}

/**
 * @interface FacturaUpdateEstado
 * Estructura para la petición de actualizar el estado de una factura.
 * Corresponde a UpdateFacturaEstadoParams en Go.
 */
export interface FacturaUpdateEstado {
  idFactura: number;
  estadoFactura: string;
}