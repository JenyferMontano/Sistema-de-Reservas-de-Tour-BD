import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { UsuarioService } from '../../../services/usuario.service';
import { Usuario } from '../../../models/usuario';
import { Router } from '@angular/router';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-listar-usuario',
  imports: [CommonModule, FormsModule],
  templateUrl: './listar-usuario.component.html',
  styleUrl: './listar-usuario.component.css',
  providers: [UsuarioService]
})
export class ListarUsuarioComponent {
  usuarios: Usuario[] = [];
  error: string = '';
  loading: boolean = false;
  search: string = '';

  constructor(private usuarioService: UsuarioService, private router: Router) { }

  ngOnInit(): void {
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {
  this.loading = true;
  this.usuarioService.getUsuarios().subscribe({
    next: (res) => {
      this.usuarios = res;
      this.loading = false;
      this.error = '';
    },
    error: (err) => {
      console.error('Error al obtener usuarios:', err);
      this.usuarios = [];
      this.loading = false;

      const mensaje = err.error?.error?.toLowerCase() || '';
      const is403 = err.status === 403;
      const isAccessDenied = mensaje.includes('acceso denegado') || 
                            mensaje.includes('rol insuficiente') ||
                            mensaje.includes('insufficient');

      if (err.status === 401 || mensaje.includes('token')) {
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
      } else if (is403 || isAccessDenied) {
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
        this.error = 'No se pudo conectar al servidor.';
      } else {
        this.error = err.error?.error || 'Error al cargar usuarios.';
      }
    }
  });
}

  getImageUrl(imageName: string): string {
    return this.usuarioService.getUsuarioImageUrl(imageName);
  }

  get usuariosFiltrados(): Usuario[] {
    const term = this.search.trim().toLowerCase();
    if (!term) return this.usuarios;
    return this.usuarios.filter(u =>
      u.username.toLowerCase().includes(term) ||
      u.rol.toLowerCase().includes(term) ||
      String(u.idpersona).includes(term)
    );
  }

  onEditar(u: Usuario) {
    this.router.navigate(['/usuario/editar', u.username]);
  }

  onEliminar(u: Usuario) {
    Swal.fire({
      title: '¿Estás seguro?',
      text: `¿Estás seguro de que deseas eliminar al usuario "${u.username}"? Esta acción no se puede revertir.`,
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      cancelButtonColor: '#6c757d',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.usuarioService.eliminarUsuario(u.username).subscribe({
          next: () => {
            this.usuarios = this.usuarios.filter(x => x.username !== u.username);
            Swal.fire({
              icon: 'success',
              title: '¡Eliminado!',
              text: 'El usuario ha sido eliminado correctamente.',
              confirmButtonColor: '#4e3e2e'
            });
          },
          error: () => {
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'No se pudo eliminar el usuario.',
              confirmButtonColor: '#4e3e2e'
            });
          }
        });
      }
    });
  }

}
