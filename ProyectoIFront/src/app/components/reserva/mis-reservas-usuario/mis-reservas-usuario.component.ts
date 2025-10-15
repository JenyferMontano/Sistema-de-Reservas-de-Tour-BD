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

    formatFechaHora(fecha: string): string {
    const d = new Date(fecha);
    return d.toLocaleString('es-CR', {
      timeZone: 'America/Costa_Rica', // ajusta según tu zona
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    });
  }

}
