import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Tour } from '../../../models/tour';

@Component({
  selector: 'app-list-tour',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './list-tour.component.html',
  styleUrls: ['./list-tour.component.css'],
  providers: [TourService]
})
export class ListTourComponent implements OnInit {
  public tours: Tour[] = [];
  public mensajeError: string = '';
  private token: string = '';

  constructor(
    private tourService: TourService,
    private usuarioService: UsuarioService
  ) {}

  ngOnInit(): void {
    this.obtenerTours();
  }

  obtenerTours(): void {
    this.token = this.usuarioService.getToken() || '';
    if (this.token.trim() === '') {
      this.mensajeError = 'Token de autenticación no definido.';
      return;
    }

    this.tourService.getTours(this.token).subscribe({
      next: (response: Tour[]) => {
        this.tours = response;
        this.mensajeError = '';
      },
      error: (err: any) => {
        console.error('Error al obtener tours:', err);
        if (err.status === 401) {
          this.mensajeError = 'No autorizado. Por favor inicia sesión.';
        } else if (err.status === 0) {
          this.mensajeError = 'No se pudo conectar al servidor.';
        } else {
          this.mensajeError = 'Error al cargar los tours.';
        }
      }
    });
  }

  getImageUrl(imageName: string | null): string {
    if (!imageName || imageName.trim() === '') {
      return 'assets/img/default-tour.png';
    }
    return this.tourService.getTourImageUrl(imageName);
  }
}