import { Component } from '@angular/core';
import { PersonaService } from '../../../services/persona.service';
import { Persona } from '../../../models/persona';
import { UsuarioService } from '../../../services/usuario.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-editar-persona',
  imports: [CommonModule, FormsModule],
  templateUrl: './editar-persona.component.html',
  styleUrl: './editar-persona.component.css',
  providers: [PersonaService],
})

export class EditarPersonaComponent {
  public status: number;
  public persona: Persona;
  private token: any;
  public idBuscar: number = 0;
  public mensaje: string = '';
  public error: string = '';
  public fechaNacString: string = '';

  constructor(
    private usuarioService: UsuarioService,
    private personaService: PersonaService
  ) {
    this.status = -1;
    this.persona = new Persona(0, '', '', '', new Date(), '', '', '');
    this.token = this.usuarioService.getToken();
  }

  buscarPersona() {
    this.personaService.getPersonaById(this.idBuscar, this.token).subscribe({
      next: (res: Persona) => {
        this.persona = {
          ...res,
          fechanac: new Date(res.fechanac),
        };
        this.fechaNacString = this.persona.fechanac
          .toISOString()
          .substring(0, 10); 
        this.status = 1;
        this.mensaje = 'Persona encontrada!';
        this.error = '';
      },
      error: (err) => {
        console.error(err);
        this.status = 0;
        this.error = 'No se encontró la persona!!!';
        this.mensaje = '';
      },
    });
  }

  actualizarPersona() {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.persona.correo)) {
      Swal.fire({
        icon: 'warning',
        title: 'Correo inválido',
        text: 'Por favor ingrese un correo válido (ej: nombre@dominio.com).',
      });
      return;
    }
    this.persona.fechanac = new Date(this.fechaNacString);
    this.personaService
      .actualizarPersona(this.persona.idpersona, this.persona, this.token)
      .subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: '¡Actualizado!',
            text: 'Persona actualizada correctamente!',
          });
          this.status = 2;
          this.resetForm();
        },
        error: (err) => {
          console.error(err);
          Swal.fire({
            icon: 'error',
            title: 'Error',
            text: 'Error al actualizar la persona!!!',
          });
          this.status = 0;
        },
      });
  }

  eliminarPersona() {
    if (!this.persona || this.persona.idpersona <= 0) return;
    Swal.fire({
      title: '¿Está seguro?',
      text: 'Esta acción eliminará la persona de forma permanente.',
      icon: 'warning',
      showCancelButton: true,
      confirmButtonColor: '#d33',
      confirmButtonText: 'Sí, eliminar',
      cancelButtonText: 'Cancelar'
    }).then((result) => {
      if (result.isConfirmed) {
        this.personaService
          .eliminarPersona(this.persona.idpersona, this.token)
          .subscribe({
            next: () => {
              Swal.fire({
                icon: 'success',
                title: '¡Eliminado!',
                text: 'Persona eliminada correctamente.',
              });
              this.status = 3;
              this.persona = new Persona(0, '', '', '', new Date(), '', '', '');
            },
            error: (err) => {
              console.error(err);
              Swal.fire({
                icon: 'error',
                title: 'Error',
                text: 'Error al eliminar la persona.',
              });
              this.status = 0;
            },
          });
      }
    });
  }

  resetForm() {
    this.persona = {
      idpersona: 0,
      nombre: '',
      apellido_1: '',
      apellido_2: '',
      fechanac: new Date(),
      direccion: '',
      telefono: '',
      correo: '',
    };
    this.fechaNacString = '';
    this.error = '';
  }
}
