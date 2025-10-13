import { Injectable } from "@angular/core"
import { server } from "./global"
import { HttpClient, HttpHeaders } from "@angular/common/http"
import { Observable } from "rxjs"
import { Usuario } from "../models/usuario"
import { LoginR } from '../models/loginR';


@Injectable({ providedIn: 'root' })
export class UsuarioService {
  private url: string;
  constructor(private _http: HttpClient) {
    this.url = server.url;
  }

  login(loginData: LoginR): Observable<any> {
    let userJSON = JSON.stringify(loginData);
    let headers = new HttpHeaders().set('Content-Type', 'application/json');
    let options = {
      headers,
    };
    return this._http.post(this.url + 'login', userJSON, options);
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

  getUsuarios(token: any): Observable<any> {
    let accessToken = 'Bearer ' + token;
    let headers = new HttpHeaders().set('Content-Type', 'application/json').set('Authorization', accessToken);
    let options = {
      headers,
    };
    return this._http.get(this.url + 'usuario/', options);
  }

  crearUsuario(usuario: Usuario, token: any): Observable<any> {
    const accessToken = 'Bearer ' + token;
    let headers = new HttpHeaders().set('Content-Type', 'application/json').set('Authorization', accessToken);
    let options = { headers };
    let data = JSON.stringify(usuario);
    return this._http.post(this.url + 'usuario/', data, options);
  }

  getUsuarioById(username: string, token: string): Observable<Usuario> {
    let accessToken = 'Bearer ' + token;
    let headers = new HttpHeaders().set('Content-Type', 'application/json').set('Authorization', accessToken);
    let options = {
      headers,
    };
    return this._http.get<Usuario>(this.url + 'usuario/' + username, options);
  }

  getUsuarioByUsername(username: string, token: string): Observable<Usuario> {
  const accessToken = 'Bearer ' + token;
  const headers = new HttpHeaders()
    .set('Content-Type', 'application/json')
    .set('Authorization', accessToken);

  return this._http.get<Usuario>(this.url + 'usuario/' + username, { headers });
}

  eliminarUsuario(username: string, token: any): Observable<any> {
    let accessToken = 'Bearer ' + token;
    let headers = new HttpHeaders().set('Content-Type', 'application/json').set('Authorization', accessToken);
    const options = {
      headers,
    };

    return this._http.delete(this.url + 'usuario/' + username, options);
  }

  actualizarUsuario(username: string, usuario: Usuario, token: any): Observable<Usuario> {
    let accessToken = 'Bearer ' + token;
    let headers = new HttpHeaders().set('Content-Type', 'application/json').set('Authorization', accessToken);
    let options = {
      headers,
    };
    let data = JSON.stringify(usuario);

    return this._http.put<Usuario>(this.url + 'usuario/' + username, data, options);
  }

  uploadImage(data: FormData, token: string): Observable<any> {
    const accessToken = 'Bearer ' + token;
    const headers = new HttpHeaders().set('Authorization', accessToken);
    return this._http.post(this.url + 'usuario/upload', data, { headers });
  }

  getUsuarioImageUrl(imageName: string): string {
    return this.url + 'usuario/images/' + imageName;
  }

}
