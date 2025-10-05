
// Para creación (envío de datos al backend)
export interface DetalleReservaCreate {
  fecha: string;
  hora: string;
  tour: number;
  cantPersonas: number;
  descuento: number;
}

// Para uso general (listar, editar, eliminar)
export interface DetalleReserva {
  idDetalle: number;
  reserva: number;
  fecha: string;
  hora: string;
  tour: number;
  cantPersonas: number;
  precio: number;
  descuento: number;
  subtotal: number;
}
