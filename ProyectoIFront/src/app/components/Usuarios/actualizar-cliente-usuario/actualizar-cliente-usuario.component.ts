import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { UsuarioService } from '../../../services/usuario.service';
import { Usuario } from '../../../models/usuario';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-actualizar-cliente-usuario',
  imports: [CommonModule, FormsModule],
  templateUrl: './actualizar-cliente-usuario.component.html',
  styleUrl: './actualizar-cliente-usuario.component.css',
  providers: [UsuarioService],
})
export class ActualizarClienteUsuarioComponent {
  usuario: Usuario;
  error: string = '';
  public status: number;
  public mensaje: string = '';
  loading: boolean = false;
  private token: any;
  public usernameBuscar: string = '';
  filename: string = '';
  imagePreview: string | null = null;
  selectedFile: File | null = null;
  nuevaPassword: string = '';

  constructor(private usuarioService: UsuarioService) {
    this.usuario = new Usuario('', '', '', 0, '');
    this.token = this.usuarioService.getToken();
    this.status = -1;
  }

  public get userToken(): any {
  return this.token;
}

 ngOnInit(): void {
  const storedToken = sessionStorage.getItem('token');
  const storedUsuario = sessionStorage.getItem('identity');

  if (storedToken && storedUsuario) {
    this.token = storedToken;
    this.usuario = JSON.parse(storedUsuario);

    this.imagePreview = this.usuario.image
      ? this.getImageUrl(this.usuario.image)
      : null;
  } else {
    this.error = 'No se encontró usuario o token en sesión';
  }
}

  updateUsuario(): void {
    if (!this.usuario.username) return;

    const actualizar = () => {
      const usuarioActualizado: any = { ...this.usuario };

      if (this.nuevaPassword && this.nuevaPassword.trim() !== '') {
        usuarioActualizado.password = this.nuevaPassword;
      } else {
        delete usuarioActualizado.password;
      }

      console.log('Enviando imagen:', usuarioActualizado.image);

      this.usuarioService
        .actualizarUsuario(
          this.usuario.username,
          usuarioActualizado,
          this.token
        )
        .subscribe({
          next: () => {
            Swal.fire({
            icon: 'success',
            title: '¡Actualización exitosa!',
            text: 'Persona actualizada correctamente.',
            timer: 3000,
            timerProgressBar: true,
            showConfirmButton: true,
          });
            this.status = 2;
            sessionStorage.setItem('usuario', JSON.stringify(usuarioActualizado));
          },
          error: (err) => {
            console.error(err);
            Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error al actualizar la persona.',
          });
            this.error = 'Error al actualizar la persona!!!';
            this.mensaje = '';
            this.status = 0;
            this.nuevaPassword = '';
          },
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
          title: 'Error',
          text: 'Error al subir la imagen.',
        });
          console.error('Error al subir imagen:', err);
          this.error = 'Error al subir la imagen.';
          this.status = 0;
        },
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

  onFileSelected(event: any): void {
  const file: File = event.target.files[0];
  if (file) {
    this.selectedFile = file;
    this.filename = file.name;
    this.usuario.image = file.name;

    const reader = new FileReader();
    reader.onload = () => {
      this.imagePreview = reader.result as string;
    };
    reader.readAsDataURL(file);
  }
}

  getImageUrl(imageName: string): string {
    return this.usuarioService.getUsuarioImageUrl(imageName);
  }
}
