import { Component } from '@angular/core';
import { PersonaService } from '../../../services/persona.service';
import { Persona } from '../../../models/persona';
import { UsuarioService } from '../../../services/usuario.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterModule } from '@angular/router';
import Swal from 'sweetalert2';
import { ActivatedRoute, Router } from '@angular/router';

@Component({
  selector: 'app-editar-persona',
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './editar-persona.component.html',
  styleUrl: './editar-persona.component.css',
  providers: [PersonaService],
})

export class EditarPersonaComponent {
  public status: number;
  public persona: Persona;
  private token: any;
  public mensaje: string = '';
  public error: string = '';
  public fechaNacString: string = '';
  public todayStr: string = new Date().toISOString().substring(0,10);

  constructor(
    private usuarioService: UsuarioService,
    private personaService: PersonaService,
    private route: ActivatedRoute,
    private router: Router
  ) {
    this.status = -1;
    this.persona = new Persona(0, '', '', '', new Date(), '', '', '');
    this.token = this.usuarioService.getToken();
  }

  private cargarPorRuta() {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!id) { return; }
    this.personaService.getPersonaById(id, this.token).subscribe({
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
        setTimeout(() => { this.mensaje = ''; }, 3000);
      },
      error: (err) => {
        console.error(err);
        this.status = 0;
        this.error = 'No se encontró la persona!!!';
        this.mensaje = '';
      },
    });
  }

  ngOnInit() {
    this.cargarPorRuta();
  }

  actualizarPersona() {
    // Validaciones
    const telRegex = /^[0-9]{8}$/;
    if (!telRegex.test(this.persona.telefono)) {
      Swal.fire({ icon: 'warning', title: 'Teléfono inválido', text: 'El teléfono debe tener 8 dígitos.' });
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
    // Mantener la fecha de nacimiento original (no se actualiza)
    this.persona.fechanac = new Date(this.fechaNacString);
    this.personaService
      .actualizarPersona(this.persona.idpersona, this.persona, this.token)
      .subscribe({
        next: () => {
          Swal.fire({
            icon: 'success',
            title: '¡Actualizado!',
            text: 'Persona actualizada correctamente!',
            confirmButtonColor: '#4e3e2e'
          }).then(() => {
            this.router.navigate(['/persona/listar']);
          });
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
