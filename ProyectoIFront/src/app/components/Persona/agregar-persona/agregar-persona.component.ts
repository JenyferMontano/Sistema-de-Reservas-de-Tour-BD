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
  public todayStr: string;

  constructor(
    private usuarioService: UsuarioService,
    private personaService: PersonaService
  ) {
    this.status = -1;
    this.persona = new Persona(0, '', '', '', new Date(), '', '', '');
    this.todayStr = new Date().toISOString().substring(0, 10);
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

    // Validación de fecha de nacimiento: no permitir futuras
    const hoy = new Date();
    const fechaNac = new Date(this.persona.fechanac);
    if (fechaNac > hoy) {
      Swal.fire({
        icon: 'warning',
        title: 'Fecha inválida',
        text: 'La fecha de nacimiento no puede ser futura.',
      });
      return;
    }

    // Validación de teléfono: 8 dígitos
    const telRegex = /^[0-9]{8}$/;
    if (!telRegex.test(this.persona.telefono)) {
      Swal.fire({
        icon: 'warning',
        title: 'Teléfono inválido',
        text: 'El teléfono debe tener 8 dígitos. Ejemplo: 88888888',
      });
      return;
    }

    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
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
        this.resetForm();
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

  private resetForm(): void {
    this.persona = new Persona(0, '', '', '', new Date(), '', '', '');
    this.todayStr = new Date().toISOString().substring(0, 10);
  }
}
