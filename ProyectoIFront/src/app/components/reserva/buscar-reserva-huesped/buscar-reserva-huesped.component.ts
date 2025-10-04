import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { ReservaService } from '../../../services/reserva.service';
import { DetalleReservaService } from '../../../services/detalleReserva.service';
import { DetalleReservaFactura, Reserva } from '../../../models/reserva';
import { Tour } from '../../../models/tour';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-buscar-reserva-huesped',
  imports: [CommonModule, FormsModule],
  templateUrl: './buscar-reserva-huesped.component.html',
  styleUrl: './buscar-reserva-huesped.component.css'
})
export class BuscarReservaHuespedComponent {

  idHuesped: number | null = null;
   reservas: (Reserva & { mostrarDetalles: boolean })[] = [];
  detallesPorReserva: { [reservaId: number]: DetalleReservaFactura[] } = {};
  tours: Tour[] = [];
  buscando = false;

  constructor(
    private reservaService: ReservaService,
    private detalleService: DetalleReservaService,
    private tourService: TourService
  ) {}

 buscarReservas(): void {
    if (this.idHuesped == null) return;
    const token = sessionStorage.getItem('token') || '';
    this.buscando = true;
    this.reservas = [];
    this.detallesPorReserva = {}; 

    this.tourService.getTours(token).subscribe({
      next: (tours) => {
        this.tours = tours;

        this.reservaService.getReservasByHuesped(this.idHuesped!, token).subscribe({
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
                error: () => this.detallesPorReserva[reserva.numreserva] = []
              });
            });
          },
          error: () => this.reservas = [],
          complete: () => this.buscando = false
        });
      },
      error: () => this.buscando = false
    });
  }

}
