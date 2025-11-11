import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {  Router } from '@angular/router';
import { UsuarioService } from '../../services/usuario.service';
import { LoginR } from '../../models/loginR';
import { CommonModule } from '@angular/common';
import Swal from 'sweetalert2';

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

          this.programarAlertasDeSesion();

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

  private programarAlertasDeSesion(): void {
    const win = window as any;

    if (win.sessionWarningTimeout) {
      clearTimeout(win.sessionWarningTimeout);
    }
    if (win.sessionExpirationTimeout) {
      clearTimeout(win.sessionExpirationTimeout);
    }

    win.sessionWarningTimeout = window.setTimeout(() => {
      Swal.fire({
        icon: 'warning',
        title: 'Sesión por expirar',
        text: 'Tu sesión expirará en 1 minuto',
        confirmButtonText: 'Entendido',
        confirmButtonColor: '#4e3e2e',
        timer: 60000,
        timerProgressBar: true
      });
    }, 840000);

    win.sessionExpirationTimeout = window.setTimeout(() => this.finalizarSesionPorTiempo(), 900000);
  }

  private finalizarSesionPorTiempo(): void {
    this.limpiarTemporizadoresGlobales();
    this._usuarioService.logout().subscribe({
      next: () => this.mostrarAlertaExpiracion(),
      error: () => this.mostrarAlertaExpiracion(),
    });
  }

  private mostrarAlertaExpiracion(): void {
    Swal.fire({
      icon: 'error',
      title: 'Sesión expirada',
      text: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.',
      confirmButtonText: 'Ir al login',
      confirmButtonColor: '#4e3e2e',
      allowOutsideClick: false,
      allowEscapeKey: false
    }).then(() => {
      sessionStorage.clear();
      this._router.navigate(['/login']);
    });
  }

  private limpiarTemporizadoresGlobales(): void {
    const win = window as any;
    if (win.sessionWarningTimeout) {
      clearTimeout(win.sessionWarningTimeout);
      win.sessionWarningTimeout = undefined;
    }
    if (win.sessionExpirationTimeout) {
      clearTimeout(win.sessionExpirationTimeout);
      win.sessionExpirationTimeout = undefined;
    }
  }
}
