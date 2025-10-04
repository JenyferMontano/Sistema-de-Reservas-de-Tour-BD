import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Tour } from '../../../models/tour';

@Component({
  selector: 'app-find-by-tour',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './find-by-tour.component.html',
  styleUrls: ['./find-by-tour.component.css'],
  providers: [TourService]
})
export class FindByTourComponent implements OnInit {
  public tipo: string = '';
  public tours: Tour[] = [];
  public tiposUnicos: string[] = [];
  public mensajeError: string = '';
  private token: string = '';

  constructor(
    private tourService: TourService,
    private usuarioService: UsuarioService
  ) {}

  ngOnInit(): void {
    this.token = this.usuarioService.getToken() || '';
    this.cargarTipos();
  }

  cargarTipos(): void {
    this.tourService.getTours(this.token).subscribe({
      next: (data: Tour[]) => {
        const tipos = data.map(t => t.tipo);
        this.tiposUnicos = [...new Set(tipos)];
      },
      error: (err) => {
        console.error('Error al obtener tipos de tour:', err);
        this.mensajeError = 'Error al cargar los tipos de tour.';
      }
    });
  }

  filtrarTours(): void {
    if (!this.tipo.trim()) {
      this.mensajeError = 'Selecciona un tipo de tour para filtrar.';
      return;
    }

    this.tourService.getToursByTipo(this.tipo, this.token).subscribe({
      next: (data: Tour[]) => {
        this.tours = data;
        this.mensajeError = '';
      },
      error: (err) => {
        console.error('Error al filtrar tours:', err);
        this.tours = [];
        this.mensajeError = 'No se encontraron tours para ese tipo.';
      }
    });
  }

  getImageUrl(nombre: string): string {
    return this.tourService.getTourImageUrl(nombre);
  }
}