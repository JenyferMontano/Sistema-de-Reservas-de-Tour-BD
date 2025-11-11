import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { finalize } from 'rxjs';
import Swal from 'sweetalert2';
import { RespaldoService } from '../../../services/respaldo.service';

interface RespaldoListado {
  nombreArchivo: string;
  tamanoMB: number | null;
  tamanoBytes: number | null;
  rutaCompleta: string;
}

@Component({
  selector: 'app-listar-respaldo',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './listar-respaldo.component.html',
  styleUrl: './listar-respaldo.component.css',
})
export class ListarRespaldoComponent implements OnInit {
  respaldos: RespaldoListado[] = [];
  cargando = false;
  ultimaRuta = '';
  rutaBase = 'C:\\backups';
  restaurandoArchivo: string | null = null;

  constructor(private respaldoService: RespaldoService) {}

  ngOnInit(): void {
    this.listarRespaldos();
  }

  actualizarLista(): void {
    this.listarRespaldos();
  }

  tamanoMB(respaldo: RespaldoListado): string {
    const valor = respaldo?.tamanoMB;
    if (valor === null || valor === undefined) {
      return 'N/A';
    }
    return Number(valor).toFixed(2);
  }

  tamanoBytes(respaldo: RespaldoListado): string {
    const valor = respaldo?.tamanoBytes;
    if (valor === null || valor === undefined) {
      return 'N/A';
    }
    return `${valor}`;
  }

  restaurar(respaldo: RespaldoListado): void {
    Swal.fire({
      title: 'Restaurar respaldo',
      html: `¿Deseas restaurar <strong>${respaldo.nombreArchivo}</strong>?`,
      input: 'textarea',
      inputLabel: 'Descripción (opcional)',
      inputPlaceholder: 'Motivo de la restauración',
      showCancelButton: true,
      confirmButtonText: 'Restaurar',
      cancelButtonText: 'Cancelar',
      confirmButtonColor: '#2e4e3e',
      cancelButtonColor: '#6c757d',
      inputValidator: () => null,
    }).then((result) => {
      if (!result.isConfirmed) {
        return;
      }
      const descripcion = (result.value as string) ?? '';
      this.ejecutarRestauracion(respaldo, descripcion);
    });
  }

  private listarRespaldos(): void {
    this.cargando = true;
    this.respaldoService
      .listarRespaldos(this.rutaBase)
      .pipe(finalize(() => (this.cargando = false)))
      .subscribe({
        next: (response) => {
          const lista = response?.data?.respaldos ?? [];
          this.ultimaRuta = this.normalizarRuta(response?.data?.ruta_busqueda ?? this.rutaBase);
          this.respaldos = lista.map((item: any) => this.buildRespaldo(item));
          if (this.respaldos.length === 0) {
            Swal.fire({
              icon: 'info',
              title: 'Sin resultados',
              text: 'No se encontraron respaldos en la carpeta predeterminada.',
              confirmButtonColor: '#4e3e2e',
            });
          }
        },
        error: (error) => {
          const mensaje = error?.error?.error ?? 'No fue posible obtener la lista de respaldos.';
          Swal.fire({
            icon: 'error',
            title: 'Error al consultar respaldos',
            text: mensaje,
            confirmButtonColor: '#4e3e2e',
          });
        },
      });
  }

  private ejecutarRestauracion(respaldo: RespaldoListado, descripcion: string): void {
    this.restaurandoArchivo = respaldo.nombreArchivo;
    const payload = {
      ruta_respaldo: respaldo.rutaCompleta,
      descripcion,
    };

    this.respaldoService
      .restaurarRespaldo(payload)
      .pipe(finalize(() => (this.restaurandoArchivo = null)))
      .subscribe({
        next: (response) => {
          Swal.fire({
            icon: 'success',
            title: 'Restauración iniciada',
            text: response?.data?.mensaje ?? 'La restauración se registró correctamente.',
            confirmButtonColor: '#2e4e3e',
          });
        },
        error: (error) => {
          const mensaje = error?.error?.error ?? 'No fue posible restaurar la base de datos.';
          Swal.fire({
            icon: 'error',
            title: 'Error al restaurar',
            text: mensaje,
            confirmButtonColor: '#4e3e2e',
          });
        },
      });
  }

  private normalizarRuta(ruta: string): string {
    if (!ruta) {
      return this.rutaBase;
    }
    return ruta.endsWith('\\') ? ruta.slice(0, -1) : ruta;
  }

  private buildRespaldo(item: any): RespaldoListado {
    const nombreArchivo = item?.['nombre_archivo'] ?? '';
    const rutaCompleta = item?.['ruta_completa'] ?? this.buildRutaCompleta(nombreArchivo);
    return {
      nombreArchivo,
      tamanoMB: item?.['tamaño_mb'] ?? item?.['tamano_mb'] ?? null,
      tamanoBytes: item?.['tamaño_bytes'] ?? item?.['tamano_bytes'] ?? null,
      rutaCompleta,
    };
  }

  private buildRutaCompleta(nombreArchivo: string): string {
    if (!nombreArchivo) {
      return this.ultimaRuta;
    }
    const separador = this.ultimaRuta.endsWith('\\') ? '' : '\\';
    return `${this.ultimaRuta}${separador}${nombreArchivo}`;
  }
}
