import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { server } from './global';
import { Tour } from '../models/tour';

@Injectable({
  providedIn: 'root'
})
export class TourService {
  public url: string;
  private accessToken: string;

  constructor(private _http: HttpClient) {
    this.url = server.url;
    this.accessToken = '';
  }

  crearTour(tour: Tour, token: string): Observable<Tour> {
    this.accessToken = 'Bearer ' + token;
    const headers = new HttpHeaders()
      .set('Content-Type', 'application/json')
      .set('Authorization', this.accessToken);

    const body = {
      idtour: tour.idtour,
      nombre: tour.nombre,
      descripcion: tour.descripcion,
      tipo: tour.tipo,
      disponibilidad: tour.disponibilidad,
      preciobase: tour.preciobase,
      ubicacion: tour.ubicacion,
      imagetour: tour.imagetour
    };

    return this._http.post<Tour>(this.url + 'tour/', body, { headers });
  }

  getTours(token: string): Observable<Tour[]> {
    const cleanToken = token.replace(/^"(.*)"$/, '$1'); // elimina comillas si las hay
    const headers = new HttpHeaders()
      .set('Content-Type', 'application/json')
      .set('Authorization', `Bearer ${cleanToken}`);
    
    return this._http.get<Tour[]>(this.url + 'tour/', { headers });
  }

  getPublicTours(token: string): Observable<Tour[]> {
    const headers = new HttpHeaders()
      .set('Authorization', 'Bearer ' + token)
      .set('Content-Type', 'application/json');

    return this._http.get<Tour[]>(this.url + 'tour/public', { headers });
  }

  getTourById(id: number, token: string): Observable<Tour> {
    const headers = new HttpHeaders().set('Authorization', 'Bearer ' + token);
    return this._http.get<Tour>(`${this.url}tour/get/${id}`, { headers });
  }

  updateTour(tour: Tour, token: string): Observable<any> {
    const headers = new HttpHeaders()
      .set('Content-Type', 'application/json')
      .set('Authorization', 'Bearer ' + token);

    const body = {
      nombre: tour.nombre,
      descripcion: tour.descripcion,
      tipo: tour.tipo,
      disponibilidad: tour.disponibilidad,
      preciobase: tour.preciobase,
      ubicacion: tour.ubicacion,
      imagetour: tour.imagetour
    };

    return this._http.put(`${this.url}tour/${tour.idtour}`, body, { headers });
  }

  deleteTour(id: number, token: string): Observable<any> {
    const headers = new HttpHeaders()
      .set('Authorization', 'Bearer ' + token);

    return this._http.delete(`${this.url}tour/${id}`, { headers });
  }

  getToursByTipo(tipo: string, token: string): Observable<Tour[]> {
    const headers = new HttpHeaders()
      .set('Authorization', 'Bearer ' + token);

    return this._http.get<Tour[]>(`${this.url}tour/tipo/${tipo}`, { headers });
  }

  uploadTourImage(data: FormData, token: string): Observable<any> {
    const accessToken = 'Bearer ' + token;
    const headers = new HttpHeaders().set('Authorization', accessToken);
    return this._http.post(this.url + 'tour/upload', data, { headers });
  }

  getTourImageUrl(imageName: string): string {
    return this.url + 'tour/img/' + imageName;
  }
}
