import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FacturaService } from '../../services/factura.service';
import { FacturaDetalle } from '../../models/facturaDetalle';
import { FormsModule } from '@angular/forms';
import { UsuarioService } from '../../services/usuario.service';

@Component({
  selector: 'app-factura',
  imports: [CommonModule, FormsModule],
  templateUrl: './factura.component.html',
  styleUrls: ['./factura.component.css'],
  providers: [FacturaService]
})
export class FacturaComponent {

  public facturas: FacturaDetalle[] = [];
  public facturasFiltradas: FacturaDetalle[] = [];
  public filtro: string = '';
  public errorMsg: string = '';
  private token: any;

  constructor(
    private facturaService: FacturaService,
    private usuarioService: UsuarioService
  ) {}

  ngOnInit(): void {
    this.token = this.usuarioService.getToken();
    if (!this.token) {
      this.errorMsg = 'Token no encontrado. Inicia sesión primero.';
      return;
    }
    this.cargarFacturas();
  }

  cargarFacturas(): void {
  this.token = this.usuarioService.getToken();

  if (!this.token || this.token.trim() === '') {
    this.errorMsg = 'No autorizado. Por favor inicia sesión.';
    return;
  }

  this.facturaService.getFacturas(this.token).subscribe({
    next: (response: any[]) => {
      this.facturas = response.map(f => ({
        idFactura: f.idfactura,
        fechaFact: f.fechafact,
        metodoPago: f.metodopago,
        iva: f.iva,
        subtotal: f.subtotal,
        total: f.total,
        numreserva: f.numreserva,
        fechareserva: f.fechareserva,
        horareserva: f.horareserva,
        cantidadpersonas: f.cantidadpersonas,
        nombrecliente: f.nombrecliente,
        apellido_1: f.apellido_1,
        apellido_2: f.apellido_2,
        nombre_tour: f.nombre_tour,
        precio_tour: f.precio_tour
      }));
      this.filtrarFacturas();
      this.errorMsg = '';
    },
    error: (err) => {
      console.error('Error al obtener facturas:', err);
      this.facturas = [];
      this.facturasFiltradas = [];

      const mensaje = err.error?.error?.toLowerCase() || '';

      if (err.status === 401 || mensaje.includes('token')) {
        this.errorMsg = 'No autorizado. Por favor inicia sesión.';
      } else if (err.status === 0) {
        this.errorMsg = 'No se pudo conectar al servidor.';
      } else {
        this.errorMsg = err.error?.error || 'Error al cargar facturas.';
      }
    }
  });
}

  filtrarFacturas(): void {
    const termino = this.filtro.toLowerCase();
    this.facturasFiltradas = this.facturas.filter(f =>
      (`${f.nombrecliente} ${f.apellido_1} ${f.apellido_2}`).toLowerCase().includes(termino)
    );
  }

  eliminarFactura(idFactura: number): void {
    if (!confirm('¿Estás seguro de que deseas eliminar esta factura?')) return;

    this.facturaService.eliminarFactura(idFactura, this.token).subscribe({
      next: () => {
        this.facturas = this.facturas.filter(f => f.idFactura !== idFactura);
        this.filtrarFacturas();
      },
      error: (err) => {
        console.error('Error al eliminar factura:', err);
        this.errorMsg = 'Error al eliminar factura.';
      }
    });
  }
}
