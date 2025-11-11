import { Component } from '@angular/core';
import Swal from 'sweetalert2';
import { DetalleReservaFactura, Reserva } from '../../../models/reserva';
import { Tour } from '../../../models/tour';
import { ReservaService } from '../../../services/reserva.service';
import { DetalleReservaService } from '../../../services/detalleReserva.service';
import { TourService } from '../../../services/tour.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UsuarioService } from '../../../services/usuario.service';
import { FacturaService } from '../../../services/factura.service';

@Component({
  selector: 'app-mis-reservas-',
  imports: [CommonModule, FormsModule],
  templateUrl: './mis-reservas-usuario.component.html',
  styleUrl: './mis-reservas-usuario.component.css'
})
export class MisReservasUsuarioComponent {
 usuario: any = null;
  reservas: (Reserva & { mostrarDetalles: boolean })[] = [];
  detallesPorReserva: { [reservaId: number]: DetalleReservaFactura[] } = {};
  tours: Tour[] = [];
  cargando = false;

  constructor(
    private reservaService: ReservaService,
    private detalleReservaService: DetalleReservaService,
    private usuarioService: UsuarioService,
    private tourService: TourService
  ) {}

  ngOnInit(): void {
    const storedUsuario = sessionStorage.getItem('identity');
    const token = sessionStorage.getItem('token');

    if (storedUsuario && token) {
      this.usuario = JSON.parse(storedUsuario);

      // 🔹 Paso 1: Obtener el usuario completo desde backend (para tener idPersona)
      this.usuarioService.getUsuarioByUsername(this.usuario.username, token).subscribe({
        next: (user) => {
          this.usuario.idPersona = user.idpersona;

          // 🔹 Paso 2: Cargar reservas del huésped (persona)
          this.cargarReservas();
        },
        error: () => {
          Swal.fire('Error', 'No se pudo obtener la información del usuario.', 'error');
        }
      });

    } else {
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: 'No hay usuario loggeado.',
      });
    }
  }

  cargarReservas(): void {
    const token = sessionStorage.getItem('token') || '';
    this.cargando = true;

    // Primero cargamos los tours para obtener los nombres
    this.tourService.getTours(token).subscribe({
      next: (tours) => {
        this.tours = tours;

        // Llamamos al endpoint de reservas por huésped
        this.reservaService.getReservasByHuesped(this.usuario.idPersona, token).subscribe({
          next: (reservas) => {
            console.log('Reservas cargadas:', reservas);
            this.reservas = reservas.map(r => ({ ...r, mostrarDetalles: false }));
            if (this.reservas.length === 0) {
            Swal.fire({
              icon: 'info',
              title: 'Sin reservas',
              text: 'No tienes reservas registradas en el sistema.',
            });
          }
          },
          error: (err) => {
            console.error(err);
            Swal.fire({
              icon: 'info',
              title: 'Sin reservas',
              text: 'No se encontraron reservas para esta persona.',
            });
            this.reservas = [];
          },
          complete: () => (this.cargando = false),
        });
      },
      error: () => {
        this.cargando = false;
        Swal.fire('Error', 'No se pudieron cargar los tours.', 'error');
      }
    });
  }

  mostrarDetallesReserva(reservaId: number): void {
    const token = sessionStorage.getItem('token') || '';

    if (!this.detallesPorReserva[reservaId]) {
      this.detalleReservaService.getDetallesByReservaId(reservaId, token).subscribe({
        next: (detalles) => {
          // Añadimos el nombre del tour a cada detalle
          this.detallesPorReserva[reservaId] = detalles.map((detalle) => {
            const tour = this.tours.find((t) => t.idtour === (detalle as any).tour);
            return {
              ...detalle,
              nombretour: tour?.nombre || 'Desconocido',
              cantpersonas: (detalle as any).cantpersonas ?? 0,
            };
          });
        },
        error: () => {
          this.detallesPorReserva[reservaId] = [];
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se pudieron cargar los detalles de la reserva.',
          });
        },
      });
    }
  }

  toggleDetalles(reserva: any): void {
    reserva.mostrarDetalles = !reserva.mostrarDetalles;

    if (reserva.mostrarDetalles) {
      this.mostrarDetallesReserva(reserva.numreserva);
    }
  }

  private parseAsLocalIfNaive(fecha: string): Date {
    const re = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,7}))?)?(?:Z|[+-]\d{2}:\d{2})?$/;
    const m = re.exec(fecha);
    if (m) {
      const [, y, mo, d, hh, mm, ss, frac] = m as any;
      const ms = frac ? +String(frac).padEnd(3, '0').slice(0, 3) : 0;
      return new Date(+y, +mo - 1, +d, +hh, +mm, ss ? +ss : 0, ms);
    }
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

  // Formatea fecha de detalle que llega como dd/MM/yyyy o yyyy-MM-dd
  formatFechaDetalle(fecha: string): string {
    if (!fecha) return '';
    // Normalizar a yyyy-MM-dd si viene como dd/MM/yyyy
    if (fecha.includes('/')) {
      const [dd, mm, yyyy] = fecha.split('/');
      const d = new Date(Number(yyyy), Number(mm) - 1, Number(dd));
      return d.toLocaleDateString('es-CR', { day: '2-digit', month: '2-digit', year: 'numeric' });
    }
    // Si viene como yyyy-MM-dd
    const d = new Date(fecha);
    return d.toLocaleDateString('es-CR', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  // Formatea hora HH:mm a formato local 12h con am/pm
  formatHoraDetalle(hora: string): string {
    if (!hora) return '';
    const raw = (hora || '').trim();

    // Casos 1: HH:mm o HH:mm:ss -> devolver HH:mm (24h)
    const m1 = raw.match(/^(\d{1,2}):(\d{2})(?::\d{2})?$/);
    if (m1) {
      const h = String(Math.min(23, Math.max(0, Number(m1[1])))).padStart(2, '0');
      const mi = m1[2];
      return `${h}:${mi}`;
    }

    // Casos 2: 1:00 PM, 01:00 pm, 1:00 p. m., etc. -> convertir a 24h HH:mm
    const lower = raw.toLowerCase();
    const m2 = lower.match(/^(\d{1,2}):(\d{2}).*?(a|p)/);
    if (m2) {
      let h = Number(m2[1]);
      const mi = m2[2];
      const isPm = m2[3] === 'p';
      if (isPm && h < 12) h += 12;
      if (!isPm && h === 12) h = 0;
      return `${String(h).padStart(2, '0')}:${mi}`;
    }

    // Fallback: intentar parsear y mostrar HH:mm
    const d = new Date(`1970-01-01T${raw}`);
    if (!isNaN(d.getTime())) {
      const h = String(d.getHours()).padStart(2, '0');
      const mi = String(d.getMinutes()).padStart(2, '0');
      return `${h}:${mi}`;
    }

    return raw; // último recurso, mostrar como viene
  }

  getEstadoClass(estado: string): string {
    const e = (estado || '').toLowerCase();
    if (e.includes('reserv')) return 'estado-reservado';
    if (e.includes('cancel')) return 'estado-cancelado';
    return 'estado-reservado';
  }

  displayEstado(estado: string): string {
    const e = (estado || '').toLowerCase().trim();
    if (e.includes('cancel')) return 'Cancelado';
    if (e.includes('reserv')) return 'Reservado';
    return estado ? estado.charAt(0).toUpperCase() + estado.slice(1) : '';
  }

}
