import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import Swal from 'sweetalert2';
import { FacturaList } from '../../../models/factura';
import { FacturaService } from '../../../services/factura.service';
import { DetalleFacturaService } from '../../../services/detalleFactura.service';
import { DetalleFacturaBase } from '../../../models/detalle-factura';
import { UsuarioService } from '../../../services/usuario.service';

@Component({
  selector: 'app-mis-facturas-usuario',
  imports: [CommonModule, RouterModule],
  templateUrl: './mis-facturas-usuario.component.html',
  styleUrl: './mis-facturas-usuario.component.css'
})
export class MisFacturasUsuarioComponent {
  usuario: any = null;
  facturas: (FacturaList & { mostrarDetalles: boolean })[] = [];
  detallesPorFactura: { [facturaId: number]: DetalleFacturaBase[] } = {};
  cargando = false;

  constructor(
    private facturaService: FacturaService,
    private detalleFacturaService: DetalleFacturaService,
    private usuarioService: UsuarioService
  ) {}

  ngOnInit(): void {
    const storedUsuario = sessionStorage.getItem('identity');
    const token = sessionStorage.getItem('token');

    if (storedUsuario && token) {
    this.usuario = JSON.parse(storedUsuario);

    // Paso 1: Obtener usuario completo desde backend
    this.usuarioService.getUsuarioByUsername(this.usuario.username, token).subscribe({
      next: (user) => {
        this.usuario.idPersona = user.idpersona;

        // Paso 2: Cargar facturas usando idPersona
        this.cargarFacturas();
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

  cargarFacturas(): void {
    const token = sessionStorage.getItem('token') || '';
    this.cargando = true;

    this.facturaService.getFacturasByPersona(this.usuario.idPersona, token).subscribe({
      next: (facturas) => {
        console.log('Facturas cargadas:', facturas);
        this.facturas = facturas.map(f => ({ ...f, mostrarDetalles: false }));
      },
      error: (err) => {
        console.error(err);
        Swal.fire({
          icon: 'info',
          title: 'Sin facturas',
          text: 'No se encontraron facturas para esta persona.',
        });
        this.facturas = [];
      },
      complete: () => (this.cargando = false),
    });
  }

  mostrarDetallesFactura(facturaId: number): void {
    const token = sessionStorage.getItem('token') || '';

    if (!this.detallesPorFactura[facturaId]) {
      this.detalleFacturaService.getDetallesByFacturaId(facturaId, token).subscribe({
        next: (detalles) => {
          this.detallesPorFactura[facturaId] = detalles;
        },
        error: () => {
          this.detallesPorFactura[facturaId] = [];
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se pudieron cargar los detalles de la factura.',
          });
        },
      });
    }
  }

  toggleDetalles(factura: any): void {
    factura.mostrarDetalles = !factura.mostrarDetalles;

    if (factura.mostrarDetalles) {
      this.mostrarDetallesFactura(factura.idFactura);
    }
  }

  descargarPDF(facturaId: number, event: MouseEvent): void {
    event.stopPropagation(); // Evita que se abra/cierre el acordeón de detalles
    const token = sessionStorage.getItem('token') || '';

    Swal.fire({
      title: 'Generando PDF...',
      text: 'Por favor, espera un momento.',
      allowOutsideClick: false,
      didOpen: () => {
        Swal.showLoading();
      }
    });

    this.facturaService.getFacturaPDF(facturaId, token).subscribe({
      next: (blob) => {
        Swal.close();
        // Crea una URL para el blob (el archivo en memoria)
        const url = window.URL.createObjectURL(blob);
        // Crea un enlace <a> temporal para iniciar la descarga
        const a = document.createElement('a');
        a.href = url;
        a.download = `factura-${facturaId}.pdf`; // Nombre del archivo
        document.body.appendChild(a);
        a.click(); // Simula un clic para descargar
        
        // Limpia
        window.URL.revokeObjectURL(url);
        a.remove();
      },
      error: () => {
        Swal.fire('Error', 'No se pudo generar el PDF.', 'error');
      }
    });
  }



}
