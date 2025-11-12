import { Injectable } from "@angular/core"
import { HttpClient, HttpHeaders } from "@angular/common/http"
import { Observable } from "rxjs"
import { Usuario } from "../models/usuario"
import { LoginR } from '../models/loginR';
import { API_BASE } from "../app.config";


@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private url: string;
  constructor(private _http: HttpClient) {
    this.url = API_BASE;
  }

  login(loginData: LoginR): Observable<any> {
    let userJSON = JSON.stringify(loginData);
    let headers = new HttpHeaders().set('Content-Type', 'application/json');
    let options = {
      headers,
    };
    return this._http.post(`${this.url}/login`, userJSON, options);
  }

  logout(): Observable<any> {
    const token = this.getToken();
    const headers = new HttpHeaders()
      .set('Content-Type', 'application/json')
      .set('Authorization', `Bearer ${token}`);
    return this._http.post(`${this.url}/logout`, {}, { headers });
  }

  getIdentity() {
    let identity = sessionStorage.getItem('identity');
    if (identity) {
      return JSON.parse(identity);
    }
    return null;
  }

  getToken() {
    return sessionStorage.getItem('token');
  }

  getUsuarios(_token?: any): Observable<any> {
    return this._http.get(`${this.url}/usuario/`);
  }

  crearUsuario(usuario: Usuario, _token?: any): Observable<any> {
    let data = JSON.stringify(usuario);
    return this._http.post(`${this.url}/usuario/`, data);
  }

  getUsuarioById(username: string, _token?: string): Observable<Usuario> {
    return this._http.get<Usuario>(`${this.url}/usuario/${username}`);
  }

  getUsuarioByUsername(username: string, _token?: string): Observable<Usuario> {
    return this._http.get<Usuario>(`${this.url}/usuario/${username}`);
  }

  eliminarUsuario(username: string, _token?: any): Observable<any> {
    return this._http.delete(`${this.url}/usuario/${username}`);
  }

  actualizarUsuario(username: string, usuario: Usuario, _token?: any): Observable<Usuario> {
    let data = JSON.stringify(usuario);
    return this._http.put<Usuario>(`${this.url}/usuario/${username}`, data);
  }

  uploadImage(data: FormData, _token?: string): Observable<any> {
    return this._http.post(`${this.url}/usuario/upload`, data);
  }

  getUsuarioImageUrl(imageName: string): string {
    return `${this.url}/usuario/images/${imageName}`;
  }

}
