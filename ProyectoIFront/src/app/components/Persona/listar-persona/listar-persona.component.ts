import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { PersonaService } from '../../../services/persona.service';
import { Persona } from '../../../models/persona';
import { UsuarioService } from '../../../services/usuario.service';

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

  constructor(
    private usuarioService: UsuarioService,
    private personaService: PersonaService
  ) {}

  ngOnInit(): void {
    this.cargarPersonas();
  }

  cargarPersonas(): void {
    this.loading = true;

    const token = this.usuarioService.getToken();

    if (!token) {
      this.error = 'Usuario no autenticado.';
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

  const mensaje = err.error?.error?.toLowerCase() || '';

  if (err.status === 401 || mensaje.includes('token')) {
    this.error = 'No autorizado. Por favor inicia sesión.';
  } else if (err.status === 0) {
    this.error = 'No se pudo conectar al servidor.';
  } else {
    this.error = err.error?.error || 'Error al cargar personas.';
  }

  this.loading = false;
}

    });
  }
}
