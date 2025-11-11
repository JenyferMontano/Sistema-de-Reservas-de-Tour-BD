import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ReservaService } from '../../../services/reserva.service';
import { TourService } from '../../../services/tour.service';
import { PersonaService } from '../../../services/persona.service';
import { UsuarioService } from '../../../services/usuario.service';
import { Persona } from '../../../models/persona';
import { DetalleReservaCreate } from '../../../models/detalle-reserva';
import { Tour } from '../../../models/tour';
import Swal from 'sweetalert2';

@Component({
  selector: 'app-nueva-reserva',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './nueva-reserva.component.html',
  styleUrls: ['./nueva-reserva.component.css'],
  providers: [TourService]
})
export class NuevaReservaComponent implements OnInit {
  huespedId: number = 0;
  rolUsuario: string = '';
  todayStr: string = '';

  nuevoDetalle: DetalleReservaCreate = {
    fecha: '',
    hora: '',
    tour: 0,
    cantPersonas: 0,
    descuento: 0,
  };

  detalles: DetalleReservaCreate[] = [];
  tours: Tour[] = [];
  personas: Persona[] = [];

  constructor(
    private reservaService: ReservaService,
    public tourService: TourService,
    private personaService: PersonaService,
    private usuarioService: UsuarioService
  ) {}

  ngOnInit(): void {
    const token = sessionStorage.getItem('token') || '';

    const identityRaw = sessionStorage.getItem('identity');
    const usuario = identityRaw ? JSON.parse(identityRaw) : null;
    this.rolUsuario = usuario?.role || '';

    // Fecha mínima (hoy)
    this.todayStr = new Date().toISOString().slice(0, 10);

    if (this.rolUsuario === 'admin') {
      this.personaService.getPersonas(token).subscribe({
        next: (data) => this.personas = data,
        error: (err) => console.error('Error al cargar personas', err)
      });
    } else if (usuario?.username) {
      // Cliente: obtener su idpersona desde backend y fijarlo como huésped
      this.usuarioService.getUsuarioByUsername(usuario.username, token).subscribe({
        next: (user) => {
          const idPersona = (user as any)?.idpersona || 0;
          this.huespedId = idPersona;
        },
        error: (err) => {
          console.error('No se pudo obtener idpersona del usuario', err);
        }
      });
    }

    this.tourService.getTours(token).subscribe({
      next: (data) => this.tours = data,
      error: (err) => console.error('Error al cargar tours', err)
    });
  }

  agregarDetalle(): void {
    if (
      this.nuevoDetalle.fecha.trim() &&
      this.nuevoDetalle.hora.trim() &&
      this.nuevoDetalle.tour > 0 &&
      this.nuevoDetalle.cantPersonas > 0
    ) {
      if (this.rolUsuario !== 'admin') {
        this.nuevoDetalle.descuento = 0;
      }
      this.detalles.push({ ...this.nuevoDetalle });
      this.nuevoDetalle = {
        fecha: '',
        hora: '',
        tour: 0,
        cantPersonas: 0,
        descuento: 0,
      };
    } else {
      Swal.fire({
        icon: 'warning',
        title: 'Campos incompletos',
        text: 'Por favor complete correctamente los campos del detalle.',
        confirmButtonColor: '#4e3e2e'
      });
    }
  }

  eliminarDetalle(index: number): void {
    this.detalles.splice(index, 1);
  }

  crearReserva(): void {
  const token = sessionStorage.getItem('token') || '';
  const identityRaw = sessionStorage.getItem('identity');
  const usuario = identityRaw ? JSON.parse(identityRaw) : null;

  if (!usuario || !usuario.username) {
    Swal.fire({
      icon: 'error',
      title: 'Error de autenticación',
      text: 'No se pudo obtener el usuario autenticado.',
      confirmButtonColor: '#4e3e2e'
    });
    return;
  }

  if (this.huespedId <= 0) {
    Swal.fire({
      icon: 'warning',
      title: 'ID de huésped requerido',
      text: 'Debe ingresar un ID de huésped válido.',
      confirmButtonColor: '#4e3e2e'
    });
    return;
  }

  if (this.detalles.length === 0) {
    Swal.fire({
      icon: 'warning',
      title: 'Detalles requeridos',
      text: 'Debe agregar al menos un detalle.',
      confirmButtonColor: '#4e3e2e'
    });
    return;
  }

  // FORMATO CORRECTO
  const fecha = new Date();
  const fechaReservaFormateada = `${fecha.getDate().toString().padStart(2,'0')}/${(fecha.getMonth()+1).toString().padStart(2,'0')}/${fecha.getFullYear()} ${fecha.getHours().toString().padStart(2,'0')}:${fecha.getMinutes().toString().padStart(2,'0')}`;

  const payload = {
  usuario: usuario.username,
  huesped: this.huespedId,
  estadoreserva: 'reservado',
  fechaReserva: fechaReservaFormateada,
  detalles: this.detalles.map(det => {
    // Convertir fecha detalle de "yyyy-MM-dd" a "dd/MM/yyyy"
    const [yyyy, mm, dd] = det.fecha.split('-');
    const fechaDetalleFormateada = `${dd}/${mm}/${yyyy}`;

    return {
      ...det,
      fecha: fechaDetalleFormateada,
      descuento: this.rolUsuario === 'admin' ? det.descuento : 0
    };
  })
};

  this.reservaService.createReserva(payload, token).subscribe({
    next: () => {
      Swal.fire({
        icon: 'success',
        title: '¡Reserva creada!',
        text: 'Reserva creada correctamente.',
        confirmButtonColor: '#4e3e2e'
      });
      this.detalles = [];
      this.huespedId = 0;
    },
    error: (err) => {
      console.error(err);
      Swal.fire({
        icon: 'error',
        title: 'Error',
        text: 'Error al crear la reserva.',
        confirmButtonColor: '#4e3e2e'
      });
    },
  });
}

  trackTour(index: number, tour: Tour): number{
    return tour.idtour;
  }
}
