import { Component } from '@angular/core';
import { UsuarioService } from '../../../services/usuario.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Usuario } from '../../../models/usuario';
import { PersonaService } from '../../../services/persona.service';
import { Persona } from '../../../models/persona';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-usuario',
  imports: [CommonModule, FormsModule],
  templateUrl: './usuario.component.html',
  styleUrl: './usuario.component.css',
  providers: [UsuarioService]
})
export class UsuarioComponent {
  public status: string = '';
  public filename: string = '';
  public usuario: Usuario;
  public personas: Persona[] = [];
  public imagePreview: string | null = null;;

  constructor(
    private _usuarioService: UsuarioService,
    private personaService: PersonaService
  ) {
    this.usuario = new Usuario("", "", "", 0, "")
  }

  ngOnInit(): void {
    const token = this._usuarioService.getToken();
    if (token) {
      this.personaService.getPersonas(token).subscribe({
        next: (res) => {
          this.personas = res;
        },
        error: (err) => {
          console.error('Error cargando personas:', err);
        }
      });
    }
  }

  onSubmit(usuarioForm: any) {
    const token = this._usuarioService.getToken();
    if (!token) {
      Swal.fire({
        icon: 'error',
        title: 'Autenticación requerida',
        text: 'Token de autenticación no definido.',
      });
      this.status = 'unauthorized';
      return;
    }

    this._usuarioService.crearUsuario(this.usuario, token).subscribe({
      next: (res) => {
        console.log('Usuario creado:', res);
        Swal.fire({
          icon: 'success',
          title: 'Éxito',
          text: '¡Usuario registrado correctamente!',
          confirmButtonColor: '#4e3e2e',
        });
        this.status = 'success';
        this.resetForm(usuarioForm);
      },
      error: (err) => {
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Ocurrió un problema al registrar el usuario!!!',
        });
        console.error('Error al crear usuario:', err);
        this.status = 'error';
      }
    });
  }

  uploadImage(e: any): void {
    const file: File = e.target.files[0];
    if (file) {
      this.filename = file.name;
      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview = reader.result as string;
      };
      reader.readAsDataURL(file);
      const formData = new FormData();
      formData.append('file0', file);

      const token = this._usuarioService.getToken();
      if (!token) {
        Swal.fire('No autorizado', 'Token no encontrado.', 'warning');
        this.status = 'unauthorized';
        return;
      }

      this._usuarioService.uploadImage(formData, token).subscribe({
        next: (response) => {
          Swal.fire('¡Imagen subida!', 'Se ha subido la imagen correctamente.', 'success');
          console.log('Imagen subida:', response);
          this.usuario.image = response.file_name;
        },
        error: (error) => {
          Swal.fire({
            icon: 'error',
            title: 'Error al subir imagen',
            text: 'No se pudo subir la imagen!!',
          });
          console.error('Error al subir imagen', error);
          this.status = 'error';
        }
      });
    }
  }

  resetForm(form: any): void {
  form.resetForm();
  this.usuario = new Usuario("", "", "", 0, ""); 
  this.imagePreview = null;
  this.filename = '';
}

}
