import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PersonaService } from '../../../services/persona.service';
import { Persona } from '../../../models/persona';
import { UsuarioService } from '../../../services/usuario.service';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-agregar-persona',
  imports: [CommonModule, FormsModule],
  templateUrl: './agregar-persona.component.html',
  styleUrl: './agregar-persona.component.css',
  providers: [PersonaService],
})
export class AgregarPersonaComponent {
  public status: number;
  public persona: Persona;
  private token: any;

  constructor(
    private usuarioService: UsuarioService,
    private personaService: PersonaService
  ) {
    this.status = -1;
    this.persona = new Persona(0, '', '', '', new Date(), '', '', '');
  }

  get fechaNacString(): string {
    if (!this.persona.fechanac) return '';
    return this.persona.fechanac.toISOString().substring(0, 10);
  }

  set fechaNacString(value: string) {
    this.persona.fechanac = new Date(value);
  }

  crearPersona() {
    this.token = this.usuarioService.getToken();
    if (!this.token) {
      Swal.fire({
        icon: 'error',
        title: 'Autenticación requerida',
        text: 'Token de autenticación no definido.',
      });
      return;
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.persona.correo)) {
      Swal.fire({
        icon: 'warning',
        title: 'Correo inválido',
        text: 'Por favor ingrese un correo válido (ej: nombre@dominio.com).',
      });
      return;
    }
    this.personaService.crearPersona(this.persona, this.token).subscribe({
      next: (response: any) => {
        Swal.fire({
          icon: 'success',
          title: 'Éxito',
          text: '¡Persona registrada correctamente!',
          confirmButtonColor: '#4e3e2e',
        });
        console.log('Respuesta:', response);
      },
      error: (err: Error) => {
        Swal.fire({
          icon: 'error',
          title: 'Error',
          text: 'Ocurrió un problema al registrar la persona.',
        });
        console.error('Error al crear persona:', err);
      },
    });
  }
}
