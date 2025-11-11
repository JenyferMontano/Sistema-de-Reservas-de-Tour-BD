import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { server } from './global';

export interface RespaldoPayload {
  ruta_respaldo: string;
  descripcion?: string;
}

export interface OperacionRespaldo {
  resultado: string;
  archivo_respaldo?: string;
  archivo_restaurado?: string;
  usuario_ejecutor?: string;
  fecha_respaldo?: string;
  fecha_restauracion?: string;
  mensaje?: string;
  mensaje_error?: string;
  tiempo_ejecucion_ms?: number;
}

@Injectable({
  providedIn: 'root',
})
export class RespaldoService {
  private readonly baseUrl = `${server.url}respaldo`;

  constructor(private http: HttpClient) {}

  crearRespaldo(payload: RespaldoPayload): Observable<any> {
    return this.http.post(`${this.baseUrl}/respaldo`, payload);
  }

  restaurarRespaldo(payload: RespaldoPayload): Observable<any> {
    return this.http.post(`${this.baseUrl}/restaurar`, payload);
  }

  listarRespaldos(rutaRespaldos: string): Observable<any> {
    const params = new HttpParams().set('ruta_respaldos', rutaRespaldos);
    return this.http.get(`${this.baseUrl}/respaldos`, { params });
  }

  obtenerAuditoria(limit = 50, offset = 0): Observable<any> {
    const params = new HttpParams()
      .set('limit', limit)
      .set('offset', offset);
    return this.http.get(`${this.baseUrl}/auditoria`, { params });
  }
}

