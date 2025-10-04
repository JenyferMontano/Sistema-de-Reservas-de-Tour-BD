import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Tour } from '../../../models/tour';

@Component({
  selector: 'app-new-tour',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './new-tour.component.html',
  styleUrls: ['./new-tour.component.css'],
  providers: [TourService]
})
export class NewTourComponent {
  public tour: Tour;
  public mensajeError: string = '';
  public mensajeExito: string = '';
  public status: number = -1;
  private token: string = '';
  public selectedFile: File | null = null;
  public filename: string = '';
  public imagePreview: string = '';

  constructor(
    private tourService: TourService,
    private usuarioService: UsuarioService
  ) {
    this.tour = {
      idtour: 0,
      nombre: '',
      descripcion: '',
      tipo: '',
      disponibilidad: 1,
      preciobase: 0,
      ubicacion: '',
      imagetour: ''
    };
  }

  uploadTourImage(event: any): void {
    const file: File = event.target.files[0];
    if (!file) return;

    this.selectedFile = file;
    this.filename = file.name;

    const reader = new FileReader();
    reader.onload = () => {
      this.imagePreview = reader.result as string;
    };
    reader.readAsDataURL(file);
  }

  crearTour(): void {
  
    this.token = this.usuarioService.getToken() || '';
    console.log('TOKEN QUE SE ESTÁ ENVIANDO:', this.token);
    
    if (!this.token.trim()) {
      this.mensajeError = 'Token de autenticación no definido.';
      this.ocultarMensajes();
      return;
    }

    if (!this.selectedFile) {
      this.mensajeError = 'Debe seleccionar una imagen para el tour.';
      this.ocultarMensajes();
      return;
    }

    const formData = new FormData();
    formData.append('file0', this.selectedFile);

    this.tourService.uploadTourImage(formData, this.token).subscribe({
      next: (res) => {
        this.tour.imagetour = res.file_name;

       this.tour.disponibilidad = Number(this.tour.disponibilidad);
        console.log('Objeto Tour a enviar:', this.tour);
  
        this.tourService.crearTour(this.tour, this.token).subscribe({
          next: () => {
            this.finalizarCreacion('¡Tour e imagen creados con éxito!');
          },
          error: (err) => {
            this.status = 0;
            this.manejarError(err);
          }
        });
      },
      error: () => {
        this.mensajeError = 'Error al subir la imagen.';
        this.ocultarMensajes();
      }
    });
  }

  private finalizarCreacion(mensaje: string): void {
    this.status = 1;
    this.mensajeExito = mensaje;
    this.mensajeError = '';
    this.tour = {
      idtour: 0,
      nombre: '',
      descripcion: '',
      tipo: '',
      disponibilidad: 1,
      preciobase: 0,
      ubicacion: '',
      imagetour: ''
    };
    this.selectedFile = null;
    this.imagePreview = '';
    this.filename = '';
    this.ocultarMensajes();
  }

  private manejarError(err: any): void {
    const errorMsg: string = err?.error?.error || err?.error?.message || '';
    if (errorMsg.includes('Duplicate entry') || errorMsg.includes('1062')) {
      this.mensajeError = 'El ID del tour ya existe.';
    } else if (err.status === 400) {
      this.mensajeError = 'Datos inválidos. Revisa el formulario.';
    } else if (err.status === 500) {
      this.mensajeError = 'Error interno del servidor.';
    } else {
      this.mensajeError = 'Error inesperado al crear el tour.';
    }
    this.mensajeExito = '';
    this.ocultarMensajes();
  }

  private ocultarMensajes(): void {
    setTimeout(() => {
      this.mensajeError = '';
      this.mensajeExito = '';
    }, 4000);
  }
}