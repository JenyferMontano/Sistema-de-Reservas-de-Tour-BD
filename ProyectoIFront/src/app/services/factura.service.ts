import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { server } from './global';
import { FacturaBase, FacturaCreateRequest, FacturaListALL, FacturaList, FacturaUpdateEstado } from '../models/factura';

@Injectable({
  providedIn: 'root'
})
export class FacturaService {
  private url: string;

  constructor(private http: HttpClient) {
    this.url = server.url;
  }

  private getAuthHeaders(token: string): HttpHeaders {
    return new HttpHeaders()
      .set('Authorization', 'Bearer ' + token)
      .set('Content-Type', 'application/json');
  }

  createFactura(factura: FacturaCreateRequest, token: string): Observable<any> {
    return this.http.post(`${this.url}factura/`, factura, {
      headers: this.getAuthHeaders(token)
    });
  }

  getAllFacturas(token: string): Observable<FacturaListALL[]> {
    return this.http.get<FacturaListALL[]>(`${this.url}factura/`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getFacturaById(id: number, token: string): Observable<FacturaBase> {
    return this.http.get<FacturaBase>(`${this.url}factura/${id}`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getFacturasByUsuario(usuario: string, token: string): Observable<FacturaList[]> {
    return this.http.get<FacturaList[]>(`${this.url}factura/usuario/${usuario}`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getFacturaByReserva(reservaId: number, token: string): Observable<FacturaBase> {
    return this.http.get<FacturaBase>(`${this.url}factura/reserva/${reservaId}`, {
      headers: this.getAuthHeaders(token)
    });
  }

  updateFacturaEstado(updateData: FacturaUpdateEstado, token: string): Observable<any> {
    return this.http.put(`${this.url}factura/estado`, updateData, {
      headers: this.getAuthHeaders(token)
    });
  }

  deleteFactura(id: number, token: string): Observable<any> {
    return this.http.delete(`${this.url}factura/${id}`, {
      headers: this.getAuthHeaders(token)
    });
  }
}
