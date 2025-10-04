import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {  Router } from '@angular/router';
import { UsuarioService } from '../../services/usuario.service';
import { LoginR } from '../../models/loginR';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
  providers:[UsuarioService]
})

export class LoginComponent {
  public status: number;
  public loginData: LoginR;

  constructor(
    private _usuarioService: UsuarioService,
    private _router: Router
  ) {
     this.status = -1;
    this.loginData = { email: '', password: '' };;
  }

    onSubmit() {
    this._usuarioService.login(this.loginData).subscribe({
      next: (response: any) => {
        if (response.access_token && response.user) {
          sessionStorage.setItem('token', response.access_token);
          sessionStorage.setItem('identity', JSON.stringify(response.user));
          this._router.navigate(['']);

          setTimeout(() => {
            alert('Tu sesión expirará en 1 minuto');
          }, 840000); // 14 min 
          setTimeout(() => {
            alert(
              'Tu sesión ha expirado. Por favor, inicia sesión nuevamente!!!'
            );
            sessionStorage.clear();
            this._router.navigate(['/login']);
          }, 900000); // 15 min
        } else {
          this.status = 0; 
        }
      },
      error: (err) => {
        console.error('Error en login:', err);
        if (err.status === 401) {
          this.status = 0; 
        } else {
          this.status = 1; 
        }
      }
    });
  }
}
