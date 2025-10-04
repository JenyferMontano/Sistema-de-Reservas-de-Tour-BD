import { DetalleReserva } from './detalle-reserva';
export class Reserva {
  constructor(
    public numreserva: number,
    public estadoreserva: string,
    public fechareserva: string,
    public subtotal: number,
    public impuesto: number,
    public total: number,
    public nombreusuario: string,
    public nombrecliente: string,
    public apellido_1: string,
    public apellido_2: string,
    public detalles?: DetalleReserva[] // relacionado
  ) {}
}

export interface DetalleReservaFactura {
  fecha: string;
  hora: string;
  nombretour: string;     
  cantpersonas: number;
  precio: number;
  descuento: number;
  subtotal: number;
}
