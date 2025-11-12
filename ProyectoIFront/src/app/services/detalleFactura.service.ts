import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE } from '../app.config';
import { DetalleFacturaBase, DetalleFacturaCompleto } from '../models/detalle-factura';

@Injectable({
  providedIn: 'root'
})
export class DetalleFacturaService {
  private readonly url = API_BASE;

  constructor(private http: HttpClient) {}

  private getAuthHeaders(token: string): HttpHeaders {
    return new HttpHeaders()
      .set('Authorization', 'Bearer ' + token)
      .set('Content-Type', 'application/json');
  }

  getAllDetalles(token: string): Observable<DetalleFacturaCompleto[]> {
    return this.http.get<DetalleFacturaCompleto[]>(`${this.url}/detallefactura/`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getDetalleById(id: number, token: string): Observable<DetalleFacturaBase> {
    return this.http.get<DetalleFacturaBase>(`${this.url}/detallefactura/${id}`, {
      headers: this.getAuthHeaders(token)
    });
  }

  getDetallesByFacturaId(facturaId: number, token: string): Observable<DetalleFacturaBase[]> {
    return this.http.get<DetalleFacturaBase[]>(`${this.url}/detallefactura/factura/${facturaId}`, {
      headers: this.getAuthHeaders(token)
    });
  }
}
