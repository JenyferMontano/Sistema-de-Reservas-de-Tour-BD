import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE } from '../app.config';
import { DetalleReserva, DetalleReservaCreate } from '../models/detalle-reserva';

@Injectable({
  providedIn: 'root'
})
export class DetalleReservaService {
  private readonly url = API_BASE;

  constructor(private http: HttpClient) {}

  private getAuthHeaders(token: string): HttpHeaders {
    return new HttpHeaders()
      .set('Authorization', 'Bearer ' + token)
      .set('Content-Type', 'application/json');
  }

  getAllDetalles(token: string): Observable<DetalleReserva[]> {
    return this.http.get<DetalleReserva[]>(`${this.url}/detallereserva/`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getDetalleById(id: number, token: string): Observable<DetalleReserva> {
    return this.http.get<DetalleReserva>(`${this.url}/detallereserva/${id}`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getDetallesByReservaId(reservaId: number, token: string): Observable<DetalleReserva[]> {
    return this.http.get<DetalleReserva[]>(`${this.url}/detallereserva/reserva/${reservaId}`, {
      headers: this.getAuthHeaders(token)
    });
  }

  createDetalle(detalle: DetalleReservaCreate, token: string): Observable<any> {
    return this.http.post(`${this.url}/detallereserva/`, detalle, {
      headers: this.getAuthHeaders(token)
    });
  }

  updateDetalle(id: number, detalle: DetalleReservaCreate, token: string): Observable<any> {
    return this.http.put(`${this.url}/detallereserva/${id}`, detalle, {
      headers: this.getAuthHeaders(token)
    });
  }

  deleteDetalle(id: number, token: string): Observable<any> {
    return this.http.delete(`${this.url}/detallereserva/${id}`, {
      headers: this.getAuthHeaders(token)
    });
  }
}
