import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Reserva } from '../models/reserva';
import { server } from './global';

@Injectable({
  providedIn: 'root'
})
export class ReservaService {
  public url: string;

  constructor(private _http: HttpClient) {
    this.url = server.url;
  }

  getAllReservas(): Observable<Reserva[]> {
    return this._http.get<Reserva[]>(this.url + 'reserva/');
  }

  getReservaById(id: number): Observable<Reserva> {
    return this._http.get<Reserva>(this.url + 'reserva/' + id);
  }

  getReservasByHuesped(id: number, token: string): Observable<Reserva[]> {
    const headers = new HttpHeaders().set('Authorization', 'Bearer ' + token);
    return this._http.get<Reserva[]>(this.url + 'reserva/huesped/' + id, { headers });
  }

getReservasByUsuario(usuario: string, token: string): Observable<Reserva[]> {
  const headers = new HttpHeaders().set('Authorization', 'Bearer ' + token);
  return this._http.get<Reserva[]>(this.url + 'reserva/usuario/' + usuario, { headers });
}
  createReserva(data: any, token: string): Observable<any> {
    const headers = new HttpHeaders()
      .set('Authorization', 'Bearer ' + token)
      .set('Content-Type', 'application/json');

    return this._http.post(this.url + 'reserva/crear', data, { headers });
  }

  deleteReserva(id: number, token: string): Observable<any> {
    const headers = new HttpHeaders().set('Authorization', 'Bearer ' + token);
    return this._http.delete(this.url + 'reserva/' + id, { headers });
  }

  updateEstadoReserva(numReserva: number, estado: string, token: string): Observable<any> {
    const headers = new HttpHeaders().set('Authorization', 'Bearer ' + token);
    const body = {
      numReserva: numReserva,
      estadoReserva: estado
    };
    return this._http.put(this.url + 'reserva/estado', body, { headers });
  }
  getMisReservas(token: string): Observable<Reserva[]> {
    const headers = new HttpHeaders().set('Authorization', 'Bearer ' + token);
    return this._http.get<Reserva[]>(this.url, { headers });
  }

}



