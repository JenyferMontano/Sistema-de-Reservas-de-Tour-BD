import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TourService } from '../../../services/tour.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Tour } from '../../../models/tour';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';

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
  public search: string = '';

  constructor(
    private tourService: TourService,
    private usuarioService: UsuarioService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.obtenerTours();
  }

  obtenerTours(): void {
    this.token = this.usuarioService.getToken() || '';
    if (this.token.trim() === '') {
      Swal.fire({
        icon: 'error',
        title: 'Error de autenticación',
        text: 'Token de autenticación no definido.',
        confirmButtonColor: '#4e3e2e'
      });
      return;
    }

    this.tourService.getTours(this.token).subscribe({
      next: (response: Tour[]) => {
        this.tours = response;
        this.mensajeError = '';
      },
      error: (err: any) => {
        console.error('Error al obtener tours:', err);
        const errorMsg = err.error?.error?.toLowerCase() || '';
        const is403 = err.status === 403;
        const isAccessDenied = errorMsg.includes('acceso denegado') || 
                              errorMsg.includes('rol insuficiente') ||
                              errorMsg.includes('insufficient');
        
        if (err.status === 401 || is403 || isAccessDenied) {
          Swal.fire({
            icon: 'error',
            title: 'Acceso denegado',
            text: 'No tienes permisos para acceder a esta sección.',
            confirmButtonText: 'Ir al login',
            confirmButtonColor: '#4e3e2e'
          }).then(() => {
            sessionStorage.clear();
            this.router.navigate(['/login']);
          });
        } else if (err.status === 0) {
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'No se pudo conectar al servidor.',
            confirmButtonColor: '#4e3e2e'
          });
        } else {
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error al cargar los tours.',
            confirmButtonColor: '#4e3e2e'
          });
        }
        this.mensajeError = '';
      }
    });
  }

  getImageUrl(imageName: string | null): string {
    if (!imageName || imageName.trim() === '') {
      return 'assets/img/default-tour.png';
    }
    return this.tourService.getTourImageUrl(imageName);
  }

  get toursFiltrados(): Tour[] {
    const term = this.search.trim().toLowerCase();
    if (!term) return this.tours;
    return this.tours.filter(t =>
      String(t.idtour).includes(term) ||
      t.nombre.toLowerCase().includes(term) ||
      t.tipo.toLowerCase().includes(term) ||
      t.ubicacion.toLowerCase().includes(term)
    );
  }

  onEditar(t: Tour) {
    this.router.navigate(['/tour/editar', t.idtour]);
  }

  onEliminar(t: Tour) {
    Swal.fire({
      title: '¿Estás seguro?',
      text: `¿Estás seguro de que deseas eliminar el tour "${t.nombre}"? Esta acción no se puede revertir.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.tourService.deleteTour(t.idtour, this.token).subscribe({
          next: () => {
            this.tours = this.tours.filter(x => x.idtour !== t.idtour);
            Swal.fire({
              icon: 'success',
              title: '¡Eliminado!',
              text: 'El tour ha sido eliminado correctamente.',
              confirmButtonColor: '#4e3e2e'
            });
          },
          error: () => {
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'No se pudo eliminar el tour.',
              confirmButtonColor: '#4e3e2e'
            });
          }
        });
      }
    });
  }
}