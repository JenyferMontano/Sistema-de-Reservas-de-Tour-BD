import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Persona } from '../models/persona';
import { API_BASE } from '../app.config';

@Injectable({
  providedIn: 'root',
})
export class PersonaService {
  public url: string;
  private accessToken: string;
  constructor(private _http: HttpClient) {
    this.url = API_BASE;
    this.accessToken = '';
  }

  getPersonas(_token?: string): Observable<any> {
    return this._http.get(`${this.url}/persona/`);
  }
  
  crearPersona(persona: Persona, _token?: any): Observable<Persona> {
    const body = {
      id_persona: persona.idpersona,
      nombre: persona.nombre,
      apellido_1: persona.apellido_1,
      apellido_2: persona.apellido_2,
      fecha_nac: persona.fechanac.toISOString(),
      direccion: persona.direccion,
      telefono: persona.telefono,
      correo: persona.correo,
    };
    const headers = _token ? new HttpHeaders().set('Authorization', 'Bearer ' + _token) : undefined;
    return this._http.post<Persona>(`${this.url}/persona/`, body, { headers });
  }

  getPersonaById(id: number, _token?: string): Observable<Persona> {
    return this._http.get<Persona>(`${this.url}/persona/get/${id}`);
  }

  actualizarPersona(id: number, persona: Persona, _token?: any): Observable<Persona> {
    const body = {
      id_persona: persona.idpersona,
      nombre: persona.nombre,
      apellido_1: persona.apellido_1,
      apellido_2: persona.apellido_2,
      fecha_nac: persona.fechanac.toISOString(),
      direccion: persona.direccion,
      telefono: persona.telefono,
      correo: persona.correo,
    };

    return this._http.put<Persona>(`${this.url}/persona/${id}`, body);
  }

  eliminarPersona(id: number, _token?: any): Observable<any> {
    return this._http.delete(`${this.url}/persona/${id}`);
  }

}