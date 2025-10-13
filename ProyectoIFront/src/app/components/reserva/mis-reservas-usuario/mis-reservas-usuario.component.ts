import { Component } from '@angular/core';
import Swal from 'sweetalert2';
import { DetalleReservaFactura, Reserva } from '../../../models/reserva';
import { Tour } from '../../../models/tour';
import { ReservaService } from '../../../services/reserva.service';
import { DetalleReservaService } from '../../../services/detalleReserva.service';
import { TourService } from '../../../services/tour.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-mis-reservas-',
  imports: [CommonModule, FormsModule],
  templateUrl: './mis-reservas-usuario.component.html',
  styleUrl: './mis-reservas-usuario.component.css'
})
export class MisReservasUsuarioComponent {
  usuario: any = null;
  huesped: string | null = null;

  reservas: (Reserva & { mostrarDetalles: boolean })[] = [];
  detallesPorReserva: { [reservaId: number]: DetalleReservaFactura[] } = {};
  tours: Tour[] = [];

  buscando = false;

  constructor(
    private reservaService: ReservaService,
    private detalleService: DetalleReservaService,
    private tourService: TourService
  ) {}

  ngOnInit(): void {
    const storedUsuario = sessionStorage.getItem('identity');
    const token = sessionStorage.getItem('token');

    if (storedUsuario && token) {
      this.usuario = JSON.parse(storedUsuario);
      this.huesped = this.usuario.username;

      if (this.huesped) {
        this.buscarReservas();
      } else {
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'No se encontró el ID del huésped en la sesión.',
        });
      }
    } else {
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: 'No hay usuario loggeado.',
      });
    }
  }

  buscarReservas(): void {
    if (!this.huesped) return;

    const token = sessionStorage.getItem('token') || '';
    this.buscando = true;
    this.reservas = [];
    this.detallesPorReserva = {};

    this.tourService.getTours(token).subscribe({
      next: (tours) => {
        this.tours = tours;

        this.reservaService.getReservasByUsuario(this.huesped!, token).subscribe({
          next: (data) => {
            this.reservas = data.map((res) => ({ ...res, mostrarDetalles: false }));

            // Obtener detalles de cada reserva
            this.reservas.forEach((reserva) => {
              this.detalleService.getDetallesByReservaId(reserva.numreserva, token).subscribe({
                next: (detalles) => {
                  this.detallesPorReserva[reserva.numreserva] = detalles.map((detalle) => {
                    const tour = this.tours.find((t) => t.idtour === (detalle as any).tour);
                    return {
                      ...detalle,
                      nombretour: tour?.nombre || 'Desconocido',
                      cantpersonas: (detalle as any).cantpersonas ?? 0,
                    };
                  });
                },
                error: () => (this.detallesPorReserva[reserva.numreserva] = []),
              });
            });
          },
          error: () => {
            this.reservas = [];
            Swal.fire({
              icon: 'info',
              title: 'Sin reservas',
              text: 'No se encontraron reservas para este usuario.',
            });
          },
          complete: () => (this.buscando = false),
        });
      },
      error: () => (this.buscando = false),
    });
  }

}
