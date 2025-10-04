import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Tour } from '../../../models/tour';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';

@Component({
  selector: 'app-edit-tour',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './edit-tour.component.html',
  styleUrls: ['./edit-tour.component.css'],
  providers: [TourService]
})
export class EditTourComponent {
  public idBuscar: number = 0;
  public tour: Tour = this.resetTour();
  public mensaje: string = '';
  public error: string = '';
  private token: string = '';

  public imagenSeleccionada: File | null = null;
  public imagenPrevisualizacion: string | null = null;

  constructor(
    private tourService: TourService,
    private usuarioService: UsuarioService
  ) {}

  buscarTour(): void {
    this.token = this.usuarioService.getToken() || '';
    if (!this.token.trim()) {
      this.error = 'Token de autenticación no definido.';
      return;
    }

    this.tourService.getTourById(this.idBuscar, this.token).subscribe({
      next: (response: Tour) => {
        this.tour = response;
        this.mensaje = '';
        this.error = '';
        this.imagenSeleccionada = null;
        this.imagenPrevisualizacion = null;
      },
      error: () => {
        this.error = 'No se encontró el tour con el ID especificado.';
        this.tour = this.resetTour();
      }
    });
  }

  actualizarTour(): void {
    this.tour.disponibilidad = Number(this.tour.disponibilidad);
    this.tourService.updateTour(this.tour, this.token).subscribe({
      next: () => {
        this.mensaje = 'Tour actualizado correctamente.';
        this.error = '';
      },
      error: () => {
        this.error = 'Error al actualizar el tour.';
      }
    });
  }

  eliminarTour(): void {
    this.tour.disponibilidad = Number(this.tour.disponibilidad);
    this.tourService.deleteTour(this.tour.idtour, this.token).subscribe({
      next: () => {
        this.mensaje = 'Tour eliminado correctamente.';
        this.tour = this.resetTour();
        this.error = '';
      },
      error: () => {
        this.error = 'Error al eliminar el tour.';
      }
    });
  }

  onFileSelected(event: any): void {
    const file = event.target.files[0];
    if (file) {
      this.imagenSeleccionada = file;

      const reader = new FileReader();
      reader.onload = () => {
        this.imagenPrevisualizacion = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  subirImagen(): void {
    if (!this.imagenSeleccionada) {
      this.error = 'Selecciona una imagen primero.';
      return;
    }

    const formData = new FormData();
    formData.append('file0', this.imagenSeleccionada);

    this.tourService.uploadTourImage(formData, this.token).subscribe({
      next: (res) => {
        this.tour.imagetour = res.file_name;
        this.mensaje = 'Imagen subida correctamente.';
        this.error = '';
      },
      error: () => {
        this.error = 'Error al subir la imagen.';
      }
    });
  }

  resetForm(): void {
    this.tour = this.resetTour();
    this.mensaje = '';
    this.error = '';
    this.imagenSeleccionada = null;
    this.imagenPrevisualizacion = null;
  }

  private resetTour(): Tour {
    return {
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
}