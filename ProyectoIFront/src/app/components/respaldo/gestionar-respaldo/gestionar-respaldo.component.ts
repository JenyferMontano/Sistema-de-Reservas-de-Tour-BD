import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { finalize } from 'rxjs';
import Swal from 'sweetalert2';
import { OperacionRespaldo, RespaldoPayload, RespaldoService } from '../../../services/respaldo.service';

@Component({
  selector: 'app-gestionar-respaldo',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './gestionar-respaldo.component.html',
  styleUrl: './gestionar-respaldo.component.css',
})
export class GestionarRespaldoComponent implements OnInit {
  creandoRespaldo = false;
  ultimoRespaldo: OperacionRespaldo | null = null;
  rutaSugerida = '';

  constructor(private respaldoService: RespaldoService) {}

  ngOnInit(): void {
    this.generarNuevaRuta();
  }

  onCrearRespaldo(): void {
    const rutaActual = this.rutaSugerida;
    const payload: RespaldoPayload = {
      ruta_respaldo: rutaActual,
      descripcion: '',
    };
    this.creandoRespaldo = true;

    this.respaldoService
      .crearRespaldo(payload)
      .pipe(finalize(() => (this.creandoRespaldo = false)))
      .subscribe({
        next: (response) => {
          this.ultimoRespaldo = response?.data;
          this.generarNuevaRuta();
          Swal.fire({
            icon: 'success',
            title: 'Respaldo creado',
            text:
              this.ultimoRespaldo?.mensaje ??
              `Respaldo generado en ${rutaActual}`,
            confirmButtonColor: '#4e3e2e',
          });
        },
        error: (error) => {
          const mensaje = error?.error?.error ?? 'No fue posible crear el respaldo.';
          Swal.fire({
            icon: 'error',
            title: 'Error al crear respaldo',
            text: mensaje,
            confirmButtonColor: '#4e3e2e',
          });
        },
      });
  }

  private generarNuevaRuta(): void {
    const now = new Date();
    const pad = (value: number) => value.toString().padStart(2, '0');
    const fecha = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}`;
    const hora = `${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
    const basePath = 'C:\\backups';
    this.rutaSugerida = `${basePath}\\reservas_tour_${fecha}_${hora}.bak`;
  }
}