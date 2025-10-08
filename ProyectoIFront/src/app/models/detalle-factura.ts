

/**
 * @interface DetalleFacturaBase
 * Estructura del detalle de factura devuelto al listar por ID de factura o en GetAll.
 * Corresponde a DetalleFacturaByFacturaRows en Go.
 */
export interface DetalleFacturaBase {
  idDetalleFactura: number;
  nombreTour: string;
  ubicacion: string;
  cantTour: number;
  precioTour: number;
  descuento: number;
  subTotal: number;
}

/**
 * @interface DetalleFacturaCompleto
 * Estructura más completa, usada en GetAllDetalleFacturas (incluye fecha/hora opcional).
 * Corresponde a DetalleFacturaAllRows en Go.
 */
export interface DetalleFacturaCompleto extends DetalleFacturaBase {
  factura: number;
  fecha?: string | null;
  hora?: string | null;
}


