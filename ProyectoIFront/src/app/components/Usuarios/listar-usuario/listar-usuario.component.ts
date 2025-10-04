import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { UsuarioService } from '../../../services/usuario.service';
import { Usuario } from '../../../models/usuario';

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

  constructor(private usuarioService: UsuarioService) { }

  ngOnInit(): void {
    this.cargarUsuarios();
  }

  cargarUsuarios(): void {
  this.loading = true;
  const token = this.usuarioService.getToken();

  if (!token) {
    this.error = 'No autorizado. Por favor inicia sesión.';
    this.loading = false;
    return;
  }

  this.usuarioService.getUsuarios(token).subscribe({
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

      if (err.status === 401 || mensaje.includes('token')) {
        this.error = 'No autorizado. Por favor inicia sesión.';
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

}
