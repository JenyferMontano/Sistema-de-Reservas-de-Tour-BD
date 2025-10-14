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
import { FacturaService } from '../../../services/factura.service';
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

  eliminarReserva(reservaId: number): void {
    const token = sessionStorage.getItem('token') || '';

    Swal.fire({
      title: '¿Estás seguro?',
      text: 'Esta acción eliminará la reserva y todos sus detalles.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar',
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6'
    }).then((result) => {
      if (result.isConfirmed) {
        this.reservaService.deleteReserva(reservaId, token).subscribe({
          next: () => {
            // Filtra la reserva eliminada del array
            this.reservas = this.reservas.filter(r => r.numreserva !== reservaId);
            // Elimina también los detalles del objeto auxiliar
            delete this.detallesPorReserva[reservaId];

            Swal.fire({
              icon: 'success',
              title: 'Eliminada',
              text: 'Reserva eliminada correctamente!'
            });
          },
          error: (err) => {
            console.error('Error eliminando reserva', err);
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'Ocurrió un error al intentar eliminar la reserva!!!'
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
      text: `¿Deseas generar una factura para la reserva #${reserva.numreserva}?`,
      icon: 'question',
      showCancelButton: true,
      confirmButtonText: 'Sí, facturar',
      cancelButtonText: 'Cancelar',
      confirmButtonColor: '#28a745',
      cancelButtonColor: '#6c757d'
    }).then((result) => {
      if (result.isConfirmed) {
        const facturaRequest: FacturaCreateRequest = {
          persona: reserva.idpersona,
          reserva: reserva.numreserva,
          estadoFactura: 'Facturada',
          metodoPago: 'Efectivo',
          iva: 13, // Asumiendo un IVA fijo del 13%
          subtotal: reserva.subtotal
        };

        this.facturaService.createFactura(facturaRequest, token).subscribe({
          next: () => {
            Swal.fire({
              icon: 'success',
              title: 'Factura creada',
              text: `La factura de la reserva #${reserva.numreserva} fue generada correctamente.`
            });
          },
          error: (err) => {
            console.error('Error creando factura', err);
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'No se pudo crear la factura. Verifique los datos o contacte soporte.'
            });
          }
        });
      }
    });
  }
}