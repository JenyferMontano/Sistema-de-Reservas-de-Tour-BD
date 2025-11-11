import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Tour } from '../../../models/tour';
import Swal from 'sweetalert2';

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
      Swal.fire({
        icon: 'error',
        title: 'Error de autenticación',
        text: 'Token de autenticación no definido.',
        confirmButtonColor: '#4e3e2e'
      });
      return;
    }

    if (!this.selectedFile) {
      Swal.fire({
        icon: 'warning',
        title: 'Imagen requerida',
        text: 'Debe seleccionar una imagen para el tour.',
        confirmButtonColor: '#4e3e2e'
      });
      return;
    }

    const formData = new FormData();
    // Adjuntar con llaves comunes por compatibilidad del backend
    formData.append('file0', this.selectedFile);
    formData.append('file', this.selectedFile);

    this.tourService.uploadTourImage(formData, this.token).subscribe({
      next: (res) => {
        this.tour.imagetour = res.file_name;

       this.tour.disponibilidad = Number(this.tour.disponibilidad);
       this.tour.preciobase = Number(this.tour.preciobase);
        console.log('Objeto Tour a enviar:', this.tour);
  
        this.tourService.crearTour(this.tour, this.token).subscribe({
          next: () => {
            this.finalizarCreacion();
          },
          error: (err) => {
            this.status = 0;
            this.manejarError(err);
          }
        });
      },
      error: () => {
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Error al subir la imagen.',
          confirmButtonColor: '#4e3e2e'
        });
      }
    });
  }

  private finalizarCreacion(): void {
    this.status = 1;
    Swal.fire({
      icon: 'success',
      title: '¡Éxito!',
      text: 'Tour creado exitosamente.',
      confirmButtonColor: '#4e3e2e'
    });
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
    this.mensajeError = '';
    this.mensajeExito = '';
  }

  private manejarError(err: any): void {
    const errorMsg: string = err?.error?.error || err?.error?.message || '';
    let mensaje = '';
    
    if (errorMsg.includes('Duplicate entry') || errorMsg.includes('1062')) {
      mensaje = 'El ID del tour ya existe.';
    } else if (err.status === 400) {
      mensaje = 'Datos inválidos. Revisa el formulario.';
    } else if (err.status === 500) {
      mensaje = 'Error interno del servidor.';
    } else {
      mensaje = 'Error inesperado al crear el tour.';
    }
    
    Swal.fire({
      icon: 'error',
      title: 'Error',
      text: mensaje,
      confirmButtonColor: '#4e3e2e'
    });
    
    this.mensajeExito = '';
    this.mensajeError = '';
  }
}