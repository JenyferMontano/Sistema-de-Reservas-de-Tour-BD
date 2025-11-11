import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ReservaService } from '../../../services/reserva.service';
import { DetalleReservaService } from '../../../services/detalleReserva.service';
import { TourService } from '../../../services/tour.service';
import { Reserva } from '../../../models/reserva';
import { DetalleReservaFactura } from '../../../models/reserva';
import { Tour } from '../../../models/tour';
import Swal from 'sweetalert2';
import { CreateFacturaResponse, FacturaService } from '../../../services/factura.service';
import { FacturaCreateRequest } from '../../../models/factura';

@Component({
  selector: 'app-listar-reserva',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './listar-reserva.component.html',
  styleUrls: ['./listar-reserva.component.css']
})
export class ListarReservaComponent implements OnInit {
  reservas: (Reserva & { mostrarDetalles: boolean })[] = [];
  detallesPorReserva: { [reservaId: number]: DetalleReservaFactura[] } = {};
  tours: Tour[] = [];
  searchText: string = '';
  filtroEstado: 'reservado' | 'cancelado' | 'facturado' | '' = '';

  constructor(
    private reservaService: ReservaService,
    private detalleService: DetalleReservaService,
    private tourService: TourService,
     private facturaService: FacturaService
  ) { }

  ngOnInit(): void {
    const token = sessionStorage.getItem('token') || '';

    this.tourService.getTours(token).subscribe({
      next: (tours) => {
        this.tours = tours;

        this.reservaService.getAllReservas().subscribe({
          next: (data) => {
            this.reservas = data.map(res => ({ ...res, mostrarDetalles: false }));
            this.reservas.forEach(reserva => {
              this.detalleService.getDetallesByReservaId(reserva.numreserva, token).subscribe({
                next: (detalles) => {
                  this.detallesPorReserva[reserva.numreserva] = detalles.map(detalle => {
                    const tour = this.tours.find(t => t.idtour === (detalle as any).tour);
                    return {
                      ...detalle,
                      nombretour: tour?.nombre || 'Desconocido',
                      cantpersonas: (detalle as any).cantpersonas ?? 0
                    };
                  });
                },
                error: (err) => {
                  console.error('Error cargando detalles para reserva', reserva.numreserva, err);
                  this.detallesPorReserva[reserva.numreserva] = [];
                }
              });
            });
          },
          error: (err) => {
            console.error('Error cargando reservas', err);
          }
        });
      },
      error: (err) => console.error('Error cargando tours', err)
    });
  }

  private parseAsLocalIfNaive(fecha: string): Date {
    // Acepta: 'YYYY-MM-DD HH:mm:ss[.fffffff][Z|+hh:mm|-hh:mm]' o con 'T' en lugar de espacio
    // Se ignora la zona si viene; siempre se construye como LOCAL para no desplazar la hora
    const re = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,7}))?)?(?:Z|[+-]\d{2}:\d{2})?$/;
    const m = re.exec(fecha);
    if (m) {
      const [, y, mo, d, hh, mm, ss, frac] = m;
      // ms: truncar a milisegundos si vienen más de 3 dígitos
      const ms = frac ? +frac.toString().padEnd(3, '0').slice(0, 3) : 0;
      return new Date(+y, +mo - 1, +d, +hh, +mm, ss ? +ss : 0, ms);
    }
    // Fallback: Date estándar
    return new Date(fecha);
  }

  formatFechaHora(fecha: string): string {
    const d = this.parseAsLocalIfNaive(fecha);
    return d.toLocaleString('es-CR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  }

  getEstadoClass(estado: string): string {
    const e = (estado || '').toLowerCase();
    if (e.includes('reserv')) return 'estado-reservado';
    if (e.includes('cancel')) return 'estado-cancelado';
    if (e.includes('factur')) return 'estado-facturado';
    return 'estado-reservado';
  }

  displayEstado(estado: string): string {
    const e = (estado || '').toLowerCase().trim();
    if (e.includes('cancel')) return 'Cancelado';
    if (e.includes('reserv')) return 'Reservado';
    if (e.includes('factur')) return 'Facturada';
    return estado ? estado.charAt(0).toUpperCase() + estado.slice(1) : '';
  }

  get reservasFiltradas(): (Reserva & { mostrarDetalles: boolean })[] {
    const term = this.searchText.trim().toLowerCase();
    return this.reservas.filter(r => {
      const coincideTexto = !term ||
        String(r.numreserva).includes(term) ||
        (r.nombreusuario || '').toLowerCase().includes(term) ||
        `${r.nombrecliente} ${r.apellido_1} ${r.apellido_2}`.toLowerCase().includes(term);
      const e = (r.estadoreserva || '').toLowerCase();
      const pasaEstado = !this.filtroEstado ||
        (this.filtroEstado === 'facturado' ? e.includes('factur') : e.includes(this.filtroEstado));
      return coincideTexto && pasaEstado;
    });
  }

  eliminarReserva(reservaId: number): void {
    const token = sessionStorage.getItem('token') || '';

    Swal.fire({
      title: '¿Cancelar reserva?',
      text: 'Esto marcará la reserva como Cancelado. No se borrará el registro.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Sí, cancelar',
      cancelButtonText: 'Mantener',
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6'
    }).then((result) => {
      if (result.isConfirmed) {
        this.reservaService.updateEstadoReserva(reservaId, 'cancelado', token).subscribe({
          next: () => {
            // Actualiza el estado en la lista sin eliminar la tarjeta
            this.reservas = this.reservas.map(r =>
              r.numreserva === reservaId ? { ...r, estadoreserva: 'cancelado' } : r
            );
            Swal.fire({
              icon: 'success',
              title: 'Reserva cancelada',
              text: 'El estado fue actualizado a Cancelado.'
            });
          },
          error: (err) => {
            console.error('Error actualizando estado', err);
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'No se pudo actualizar el estado de la reserva.'
            });
          }
        });
      }
    });
  }

  crearFactura(reserva: Reserva): void {
    const token = sessionStorage.getItem('token') || '';

    Swal.fire({
      title: '¿Crear factura?',
      text: `Reserva #${reserva.numreserva}. Selecciona el método de pago:`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Continuar',
      cancelButtonText: 'Cancelar',
      input: 'radio',
      inputOptions: {
        'Efectivo': 'Efectivo',
        'Tarjeta': 'Tarjeta'
      },
      inputValidator: (value) => {
        if (!value) return 'Selecciona un método de pago';
        return undefined as any;
      }
    }).then((result) => {
      if (result.isConfirmed) {
        const metodo = (result.value as 'Efectivo' | 'Tarjeta') || 'Efectivo';

        Swal.fire({
          title: 'Procesando...',
          text: 'Creando la factura, por favor espera.',
          allowOutsideClick: false,
          didOpen: () => Swal.showLoading()
        });

        const facturaRequest: FacturaCreateRequest = {
          persona: reserva.idpersona,
          reserva: reserva.numreserva,
          estadoFactura: 'Pagada',
          metodoPago: metodo,
          iva: 13,
          subtotal: reserva.subtotal
        };

        this.facturaService.createFactura(facturaRequest, token).subscribe({
          next: (response: CreateFacturaResponse) => {
            Swal.fire({
              icon: 'success',
              title: '¡Factura Creada!',
              text: `La factura #${response.factura.idfactura} fue generada. Preparando descarga...`
            });
            this.descargarFacturaPDF(response.factura.idfactura, token);
            // Marcar la reserva como facturada en la lista (no eliminar)
            this.reservas = this.reservas.map(r =>
              r.numreserva === reserva.numreserva ? { ...r, estadoreserva: 'Facturada' } : r
            );
          },
          error: (err) => {
            console.error('Error creando factura', err);
            Swal.fire('Error', 'No se pudo crear la factura.', 'error');
          }
        });
      }
    });
  }


  private descargarFacturaPDF(facturaId: number, token: string): void {
    this.facturaService.getFacturaPDF(facturaId, token).subscribe({
      next: (blob) => {
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `factura-${facturaId}.pdf`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        a.remove();
      },
      error: (err) => {
        console.error('Error descargando PDF', err);
        Swal.fire('Error', 'No se pudo descargar el PDF.', 'error');
      }
    });
  }
}