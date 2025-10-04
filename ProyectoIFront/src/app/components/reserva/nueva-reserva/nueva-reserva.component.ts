import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ReservaService } from '../../../services/reserva.service';
import { TourService } from '../../../services/tour.service';
import { DetalleReservaCreate } from '../../../models/detalle-reserva';
import { Tour } from '../../../models/tour';

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

  nuevoDetalle: DetalleReservaCreate = {
    fecha: '',
    hora: '',
    tour: 0,
    cantPersonas: 0,
    descuento: 0,
  };

  detalles: DetalleReservaCreate[] = [];
  tours: Tour[] = [];

  constructor(
    private reservaService: ReservaService,
    public tourService: TourService
  ) {}

  ngOnInit(): void {
    const token = sessionStorage.getItem('token') || '';

    const identityRaw = sessionStorage.getItem('identity');
    const usuario = identityRaw ? JSON.parse(identityRaw) : null;
    this.rolUsuario = usuario?.role || '';

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
      alert('Por favor complete correctamente los campos del detalle.');
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
    alert('No se pudo obtener el usuario autenticado');
    return;
  }

  if (this.huespedId <= 0) {
    alert('Debe ingresar un ID de huésped válido.');
    return;
  }

  if (this.detalles.length === 0) {
    alert('Debe agregar al menos un detalle.');
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
/*
  const payload = {
    usuario: usuario.username,
    huesped: this.huespedId,
    estadoreserva: 'reservado',
    fechaReserva: fechaReservaFormateada,
    detalles: this.detalles.map(det => ({
      ...det,
      descuento: this.rolUsuario === 'admin' ? det.descuento : 0
    }))
  };*/

  this.reservaService.createReserva(payload, token).subscribe({
    next: () => {
      alert('✅ Reserva creada correctamente');
      this.detalles = [];
      this.huespedId = 0;
    },
    error: (err) => {
      console.error(err);
      alert('❌ Error al crear la reserva');
    },
  });
}


  /*
  crearReserva(): void {
  const token = sessionStorage.getItem('token') || '';
  const identityRaw = sessionStorage.getItem('identity');
  const usuario = identityRaw ? JSON.parse(identityRaw) : null;

  if (!usuario || !usuario.username) {
    alert('No se pudo obtener el usuario autenticado');
    return;
  }

  if (this.huespedId <= 0) {
    alert('Debe ingresar un ID de huésped válido.');
    return;
  }

  if (this.detalles.length === 0) {
    alert('Debe agregar al menos un detalle.');
    return;
  }

  const payload = {
  usuario: usuario.username,
  huesped: this.huespedId,
  estadoreserva: 'reservado',
  fechaReserva: new Date().toISOString().slice(0, 19),
  detalles: this.detalles.map(det => ({
    ...det,
    descuento: this.rolUsuario === 'admin' ? det.descuento : 0
  }))
};

  this.reservaService.createReserva(payload, token).subscribe({
    next: () => {
      alert('✅ Reserva creada correctamente');
      this.detalles = [];
      this.huespedId = 0;
    },
    error: (err) => {
      console.error(err);
      alert('❌ Error al crear la reserva');
    },
  });
} */

  trackTour(index: number, tour: Tour): number{
    return tour.idtour;
  }
}
