import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FacturaListALL } from '../../../models/factura';
import { FacturaService } from '../../../services/factura.service';
import { ReservaService } from '../../../services/reserva.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-listar-factura-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './listar-factura-admin.component.html',
  styleUrls: ['./listar-factura-admin.component.css']
})
export class ListarFacturaAdminComponent implements OnInit {
  facturas: FacturaListALL[] = [];
  searchText: string = '';
  filtroEstado: string = '';
  filtroMetodo: string = '';

  estadosDisponibles: string[] = [];
  metodosDisponibles: string[] = ['Efectivo', 'Tarjeta'];

  constructor(
    private facturaService: FacturaService,
    private reservaService: ReservaService
  ) {}

  ngOnInit(): void {
    const token = sessionStorage.getItem('token') || '';
    this.facturaService.getAllFacturas(token).subscribe({
      next: (data) => {
        this.facturas = data || [];
        // Derivar estados desde los datos (normalizados)
        const set = new Set<string>();
        this.facturas.forEach(f => set.add((f.estadofactura || '').trim()));
        this.estadosDisponibles = Array.from(set).filter(Boolean);
      },
      error: (err) => {
        console.error('Error cargando facturas', err);
      }
    });
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

  get facturasFiltradas(): FacturaListALL[] {
    const term = this.searchText.trim().toLowerCase();
    return this.facturas.filter(f => {
      const coincideTexto = !term ||
        String(f.idfactura).includes(term) ||
        String(f.idpersona).includes(term) ||
        String(f.numreserva).includes(term);

      const e = (f.estadofactura || '').toLowerCase();
      const m = (f.metodopago || '').toLowerCase();

      const pasaEstado = !this.filtroEstado || e.includes(this.filtroEstado.toLowerCase());
      const pasaMetodo = !this.filtroMetodo || m.includes(this.filtroMetodo.toLowerCase());

      return coincideTexto && pasaEstado && pasaMetodo;
    });
  }

  getEstadoClass(estado: string): string {
    const e = (estado || '').toLowerCase();
    if (e.includes('pagada') || e.includes('pagado')) return 'estado-pagada';
    if (e.includes('anulada') || e.includes('anulado')) return 'estado-anulada';
    return 'estado-pagada';
  }

  descargarPDF(facturaId: number): void {
    const token = sessionStorage.getItem('token') || '';
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

  anularFactura(facturaId: number): void {
    const token = sessionStorage.getItem('token') || '';
    const factura = this.facturas.find(f => f.idfactura === facturaId);
    const numReserva = factura?.numreserva;

    Swal.fire({
      title: '¿Anular factura?',
      text: 'Esto marcará la factura como Anulada. La reserva volverá a estado "Reservado".',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Sí, anular',
      cancelButtonText: 'Cancelar',
      confirmButtonColor: '#d33',
      cancelButtonColor: '#3085d6'
    }).then((result) => {
      if (result.isConfirmed) {
        const updateData = {
          idFactura: facturaId,
          estadoFactura: 'Anulada'
        };
        this.facturaService.updateFacturaEstado(updateData, token).subscribe({
          next: () => {
            this.facturas = this.facturas.map(f =>
              f.idfactura === facturaId ? { ...f, estadofactura: 'Anulada' } : f
            );
            // Actualizar el estado de la reserva a "reservado"
            if (numReserva) {
              this.reservaService.updateEstadoReserva(numReserva, 'reservado', token).subscribe({
                next: () => {
                  Swal.fire({
                    icon: 'success',
                    title: 'Factura y reserva actualizadas',
                    text: 'La factura fue anulada y la reserva volvió a "Reservado".'
                  });
                },
                error: (err) => {
                  console.error('Error actualizando reserva', err);
                  Swal.fire({
                    icon: 'warning',
                    title: 'Factura anulada',
                    text: 'La factura fue anulada pero no se pudo actualizar el estado de la reserva.'
                  });
                }
              });
            } else {
              Swal.fire({
                icon: 'success',
                title: 'Factura anulada',
                text: 'El estado fue actualizado a Anulada.'
              });
            }
          },
          error: (err) => {
            console.error('Error actualizando estado', err);
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'No se pudo anular la factura.'
            });
          }
        });
      }
    });
  }
}


