import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE } from '../app.config';
import { Tour } from '../models/tour';

@Injectable({
  providedIn: 'root'
})
export class TourService {
  public url: string;
  private accessToken: string;

  constructor(private _http: HttpClient) {
    this.url = API_BASE;
    this.accessToken = '';
  }

  crearTour(tour: Tour, _token?: string): Observable<Tour> {

    const body = {
      nombre: tour.nombre,
      descripcion: tour.descripcion,
      tipo: tour.tipo,
      disponibilidad: tour.disponibilidad,
      preciobase: tour.preciobase,
      ubicacion: tour.ubicacion,
      imagetour: tour.imagetour
    };

    return this._http.post<Tour>(`${this.url}/tour/`, body);
  }

  getTours(_token?: string): Observable<Tour[]> {
    return this._http.get<Tour[]>(`${this.url}/tour/`);
  }

  getPublicTours(_token?: string): Observable<Tour[]> {
    return this._http.get<Tour[]>(`${this.url}/tour/public`);
  }

  getTourById(id: number, _token?: string): Observable<Tour> {
    return this._http.get<Tour>(`${this.url}/tour/get/${id}`);
  }

  updateTour(tour: Tour, _token?: string): Observable<any> {

    const body = {
      nombre: tour.nombre,
      descripcion: tour.descripcion,
      tipo: tour.tipo,
      disponibilidad: tour.disponibilidad,
      preciobase: tour.preciobase,
      ubicacion: tour.ubicacion,
      imagetour: tour.imagetour
    };

    return this._http.put(`${this.url}/tour/${tour.idtour}`, body);
  }

  deleteTour(id: number, _token?: string): Observable<any> {
    return this._http.delete(`${this.url}/tour/${id}`);
  }

  getToursByTipo(tipo: string, _token?: string): Observable<Tour[]> {
    return this._http.get<Tour[]>(`${this.url}/tour/tipo/${tipo}`);
  }

  uploadTourImage(data: FormData, _token?: string): Observable<any> {
    return this._http.post(`${this.url}/tour/upload`, data);
  }

  getTourImageUrl(imageName: string): string {
    return `${this.url}/tour/img/${imageName}`;
  }
}
