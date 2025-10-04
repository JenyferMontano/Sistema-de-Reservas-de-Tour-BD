import { Component } from '@angular/core';
import { UsuarioService } from '../../../services/usuario.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Usuario } from '../../../models/usuario';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-editar-usuario',
  imports: [CommonModule, FormsModule],
  templateUrl: './editar-usuario.component.html',
  styleUrl: './editar-usuario.component.css',
  providers: [UsuarioService]
})
export class EditarUsuarioComponent {
  usuario: Usuario;
  error: string = '';
  public status: number;
  public mensaje: string = ''
  loading: boolean = false;
  private token: any
  public usernameBuscar: string = '';
  filename: string = '';
  imagePreview: string | null = null;
  selectedFile: File | null = null;
  nuevaPassword: string = '';

  constructor(private usuarioService: UsuarioService) {
    this.usuario = new Usuario("", "", "", 0, "")
    this.token = this.usuarioService.getToken();
    this.status = -1
  }


  buscarUsuario() {
    this.usuarioService.getUsuarioById(this.usernameBuscar, this.token).subscribe({
      next: (res: Usuario) => {
        this.usuario = res;
        this.mensaje = 'Usuario encontrado!';
        this.error = '';
        setTimeout(() => {
          this.mensaje = '';
        }, 5000);
      },
      error: (err) => {
        console.error(err);
        this.error = 'No se encontró el usuario!!!';
        this.mensaje = '';
        setTimeout(() => {
          this.error = '';
        }, 5000);
      }
    });
  }

  deleteUsuario() {
    if (!this.usuario || !this.usuario.username) return;

    Swal.fire({
      title: '¿Estás seguro?',
      text: '¡No podrás revertir esto!',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.usuarioService.eliminarUsuario(this.usuario.username, this.token).subscribe({
          next: () => {
            Swal.fire({
              icon: 'success',
              title: '¡Eliminado!',
              text: 'Usuario eliminada correctamente.',
            });
            this.status = 3;
            this.usuario = new Usuario("", "", "", 0, "");
          },
          error: (err) => {
            console.error(err);
            Swal.fire({
              icon: 'error',
              title: 'Error',
              text: 'Error al eliminar el usuario!!!',
            });
            this.status = 0;
          }
        });
      }
    });
  }

  updateUsuario(): void {
    if (!this.usuario.username) return;
    if (this.nuevaPassword && !this.validarPassword()) {
      Swal.fire({
        icon: 'error',
        title: 'Contraseña inválida',
        text: 'Debe tener al menos 8 caracteres, una mayúscula, una minúscula, un número y un símbolo.',
      });
      return;
    }

    const actualizar = () => {
      const usuarioActualizado: any = { ...this.usuario };

      if (this.nuevaPassword && this.nuevaPassword.trim() !== '') {
        usuarioActualizado.password = this.nuevaPassword;
      } else {
        delete usuarioActualizado.password;
      }

      console.log('Enviando imagen:', usuarioActualizado.image);

      this.usuarioService.actualizarUsuario(this.usuario.username, usuarioActualizado, this.token).subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: '¡Actualizado!',
            text: 'Usuario actualizado correctamente!',
          });
          this.status = 2;
        },
        error: (err) => {
          console.error(err);
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error al actualizar el usuario!!!',
          });
          this.status = 0;
          this.nuevaPassword = '';
        }
      });
    };

    if (this.selectedFile) {
      const formData = new FormData();
      formData.append('file0', this.selectedFile);
      formData.append('username', this.usuario.username);

      this.usuarioService.uploadImage(formData, this.token).subscribe({
        next: (res) => {
          this.usuario.image = res.file_name; 
          actualizar();
        },
        error: (err) => {
          Swal.fire({
            icon: 'error',
            title: 'Error al subir imagen',
            text: 'No se pudo subir la imagen!!',
          });
          this.status = 0;
        }
      });
    } else {
      actualizar();
    }
  }


  uploadImage(e: any): void {
    const file: File = e.target.files[0];
    if (file) {
      this.filename = file.name;
      this.selectedFile = file;

      const reader = new FileReader();
      reader.onload = () => {
        this.imagePreview = reader.result as string;
      };
      reader.readAsDataURL(file);
    }
  }

  validarPassword(): boolean {
    if (!this.nuevaPassword || this.nuevaPassword.trim() === '') {
      return true;
    }

    const pattern = /^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{8,}$/;
    return pattern.test(this.nuevaPassword);
  }

  resetForm(): void {
    this.usuario = new Usuario("", "", "", 0, "");
    this.nuevaPassword = '';
    this.usernameBuscar = '';
    this.imagePreview = null;
    this.selectedFile = null;
    this.filename = '';
    this.mensaje = '';
    this.error = '';
    this.status = -1;
  }

  getImageUrl(imageName: string): string {
    return this.usuarioService.getUsuarioImageUrl(imageName);
  }
}
