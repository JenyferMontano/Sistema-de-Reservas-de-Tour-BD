import { Component } from '@angular/core';
import { Router, RouterLink, RouterOutlet,  } from '@angular/router';
import { PersonaService } from "./services/persona.service"
import { UsuarioService } from './services/usuario.service';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, CommonModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  title = 'ProyectoIFront';
  private checkIdentity;
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
    sessionStorage.removeItem('identity');
    sessionStorage.removeItem('token');
  }
}

