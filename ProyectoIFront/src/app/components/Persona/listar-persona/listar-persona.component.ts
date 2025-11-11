import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { PersonaService } from '../../../services/persona.service';
import { Persona } from '../../../models/persona';
import { UsuarioService } from '../../../services/usuario.service';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-listar-persona',
  imports: [CommonModule, FormsModule],
  templateUrl: './listar-persona.component.html',
  styleUrl: './listar-persona.component.css',
  providers: [PersonaService],
})
export class ListarPersonaComponent {
  personas: Persona[] = [];
  error: string = '';
  loading: boolean = false;
  search: string = '';

  constructor(
    private usuarioService: UsuarioService,
    private personaService: PersonaService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.cargarPersonas();
  }

  cargarPersonas(): void {
    this.loading = true;

    const token = this.usuarioService.getToken();

    if (!token) {
      Swal.fire({
        icon: 'error',
        title: 'Error de autenticación',
        text: 'Usuario no autenticado.',
        confirmButtonColor: '#4e3e2e'
      });
      this.loading = false;
      return;
    }

    this.personaService.getPersonas(token).subscribe({
      next: (res) => {
        this.personas = res;
        this.loading = false;
      },
      error: (err) => {
        console.error('Error al obtener personas:', err);

        const errorMsg = err.error?.error?.toLowerCase() || '';
        const is403 = err.status === 403;
        const isAccessDenied = errorMsg.includes('acceso denegado') || 
                              errorMsg.includes('rol insuficiente') ||
                              errorMsg.includes('insufficient');
        
        if (err.status === 401 || errorMsg.includes('token') || is403 || isAccessDenied) {
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
            text: err.error?.error || 'Error al cargar personas.',
            confirmButtonColor: '#4e3e2e'
          });
        }

        this.error = '';
        this.loading = false;
      }

    });
  }

  get personasFiltradas(): Persona[] {
    const term = this.search.trim().toLowerCase();
    if (!term) return this.personas;
    return this.personas.filter(p =>
      String(p.idpersona).includes(term) ||
      p.nombre.toLowerCase().includes(term) ||
      p.apellido_1.toLowerCase().includes(term) ||
      p.apellido_2.toLowerCase().includes(term) ||
      p.correo.toLowerCase().includes(term) ||
      p.telefono.toLowerCase().includes(term) ||
      p.direccion.toLowerCase().includes(term)
    );
  }

  onEditar(persona: Persona) {
    this.router.navigate(['/persona/editar', persona.idpersona]);
  }

  onEliminar(persona: Persona) {
    const token = this.usuarioService.getToken();
    Swal.fire({
      title: '¿Eliminar persona?',
      text: `Se eliminará la persona #${persona.idpersona}. Esta acción no se puede deshacer.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar',
      confirmButtonColor: '#d33'
    }).then((result: any) => {
      if (result.isConfirmed) {
        this.personaService.eliminarPersona(persona.idpersona, token).subscribe({
          next: () => {
            this.personas = this.personas.filter(p => p.idpersona !== persona.idpersona);
            Swal.fire({ icon: 'success', title: 'Eliminado', text: 'Persona eliminada correctamente.', confirmButtonColor: '#4e3e2e' });
          },
          error: () => {
            this.error = 'No se pudo eliminar la persona.';
            Swal.fire({ icon: 'error', title: 'Error', text: 'No se pudo eliminar la persona.' });
          }
        });
      }
    });
  }
}
