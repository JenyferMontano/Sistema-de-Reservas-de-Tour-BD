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

  getReservasByHuesped(id: number, _token?: string): Observable<Reserva[]> {
    return this._http.get<Reserva[]>(this.url + 'reserva/huesped/' + id);
  }

getReservasByUsuario(usuario: string, _token?: string): Observable<Reserva[]> {
  return this._http.get<Reserva[]>(this.url + 'reserva/usuario/' + usuario);
}
  createReserva(data: any, _token?: string): Observable<any> {
    return this._http.post(this.url + 'reserva/crear', data);
  }

  deleteReserva(id: number, _token?: string): Observable<any> {
    return this._http.delete(this.url + 'reserva/' + id);
  }

  updateEstadoReserva(numReserva: number, estado: string, _token?: string): Observable<any> {
    const body = {
      numReserva: numReserva,
      estadoReserva: estado
    };
    return this._http.put(this.url + 'reserva/estado', body);
  }
  getMisReservas(_token?: string): Observable<Reserva[]> {
    return this._http.get<Reserva[]>(this.url + 'reserva/mis-reservas');
  }

}



