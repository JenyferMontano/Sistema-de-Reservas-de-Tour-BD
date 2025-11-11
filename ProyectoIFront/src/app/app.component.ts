import { Component, OnDestroy } from '@angular/core';
import { Router, RouterLink, RouterOutlet,  } from '@angular/router';
import { PersonaService } from "./services/persona.service"
import { UsuarioService } from './services/usuario.service';
import { CommonModule } from '@angular/common';
import { finalize } from 'rxjs';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, CommonModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnDestroy {
  title = 'ProyectoIFront';
  private checkIdentity: any;
  public identity:any;

  constructor(
    private personaService:PersonaService,
    private usuarioService:UsuarioService,
    private router: Router
  
  ){
    this.checkIdentity = setInterval(() => {
      this.identity = this.usuarioService.getIdentity();
    }, 500);
  }

  public getUsuarioImageUrl(imageName: string): string {
    return this.usuarioService.getUsuarioImageUrl(imageName);
  }

  logout(): void {
    const token = this.usuarioService.getToken();
    if (!token || token === 'null' || token === 'undefined') {
      this.limpiarSesionLocal();
      this.router.navigate(['/login']);
      return;
    }

    this.usuarioService
      .logout()
      .pipe(finalize(() => this.router.navigate(['/login'])))
      .subscribe({
        next: () => this.limpiarSesionLocal(),
        error: () => this.limpiarSesionLocal(),
      });
  }

  hasRole(role: string): boolean {
    return (this.identity?.role || '').toLowerCase() === role.toLowerCase();
  }

  hasAnyRole(...roles: string[]): boolean {
    const currentRole = (this.identity?.role || '').toLowerCase();
    return roles.some((role) => role.toLowerCase() === currentRole);
  }

  ngOnDestroy(): void {
    if (this.checkIdentity) {
      clearInterval(this.checkIdentity);
    }
  }

  private limpiarSesionLocal(): void {
    sessionStorage.removeItem('identity');
    sessionStorage.removeItem('token');

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

