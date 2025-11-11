import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Tour } from '../../../models/tour';
import Swal from 'sweetalert2';

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
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Error al cargar los tipos de tour.',
          confirmButtonColor: '#4e3e2e'
        });
        this.mensajeError = '';
      }
    });
  }

  filtrarTours(): void {
    if (!this.tipo.trim()) {
      Swal.fire({
        icon: 'warning',
        title: 'Tipo requerido',
        text: 'Selecciona un tipo de tour para filtrar.',
        confirmButtonColor: '#4e3e2e'
      });
      return;
    }

    this.tourService.getToursByTipo(this.tipo, this.token).subscribe({
      next: (data: Tour[]) => {
        this.tours = data;
        this.mensajeError = '';
        if (data.length === 0) {
          Swal.fire({
            icon: 'info',
            title: 'Sin resultados',
            text: 'No se encontraron tours para ese tipo.',
            confirmButtonColor: '#4e3e2e'
          });
        }
      },
      error: (err) => {
        console.error('Error al filtrar tours:', err);
        this.tours = [];
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'No se encontraron tours para ese tipo.',
          confirmButtonColor: '#4e3e2e'
        });
        this.mensajeError = '';
      }
    });
  }

  getImageUrl(nombre: string): string {
    return this.tourService.getTourImageUrl(nombre);
  }
}