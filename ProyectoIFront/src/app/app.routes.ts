import { Routes } from '@angular/router';
import { HomeComponent } from './components/home/home.component';
import { LoginComponent } from './components/login/login.component';
import { ErrorComponent } from './components/error/error.component';
import { UsuarioComponent } from './components/Usuarios/usuario/usuario.component';
import { ListarPersonaComponent } from './components/Persona/listar-persona/listar-persona.component';
import { EditarPersonaComponent } from './components/Persona/editar-persona/editar-persona.component';
import { ListarUsuarioComponent } from './components/Usuarios/listar-usuario/listar-usuario.component';
import { EditarUsuarioComponent } from './components/Usuarios/editar-usuario/editar-usuario.component';
import { AgregarPersonaComponent } from './components/Persona/agregar-persona/agregar-persona.component';
import { ActualizarClienteUsuarioComponent } from './components/Usuarios/actualizar-cliente-usuario/actualizar-cliente-usuario.component';
import { ListarReservaComponent } from './components/reserva/listar-reserva/listar-reserva.component';
import { NuevaReservaComponent } from './components/reserva/nueva-reserva/nueva-reserva.component';
import { NewTourComponent } from './components/tour/new-tour/new-tour.component';
import { ListTourComponent } from './components/tour/list-tour/list-tour.component';
import { EditTourComponent } from './components/tour/edit-tour/edit-tour.component';
import { FindByTourComponent } from './components/tour/find-by-tour/find-by-tour.component';
import { BuscarReservaHuespedComponent } from './components/reserva/buscar-reserva-huesped/buscar-reserva-huesped.component';
import { MisReservasUsuarioComponent } from './components/reserva/mis-reservas-usuario/mis-reservas-usuario.component';
import { MisFacturasUsuarioComponent } from './components/factura/mis-facturas-usuario/mis-facturas-usuario.component';


export const routes: Routes = [
    { path: '', component: HomeComponent },
    { path: 'login', component: LoginComponent },
    { path: 'usuario/agregar', component: UsuarioComponent },
    { path: 'persona/agregar', component: AgregarPersonaComponent },
    { path: 'persona/listar', component: ListarPersonaComponent },
    { path: 'persona/editar', component: EditarPersonaComponent },
    { path: 'usuario/listar', component: ListarUsuarioComponent },
    { path: 'usuario/editar', component: EditarUsuarioComponent },
    { path: 'usuario/actualizar', component: ActualizarClienteUsuarioComponent },
    { path: 'reservas', component: ListarReservaComponent },
    { path: 'reservas/nueva', component: NuevaReservaComponent },
    { path: 'reservas/buscar/huesped', component: BuscarReservaHuespedComponent },
    { path: 'reservas/mis-reservas', component: MisReservasUsuarioComponent },
    { path: 'tour/agregar', component: NewTourComponent },
    { path: 'tour/listar', component: ListTourComponent },
    { path: 'tour/editar', component: EditTourComponent },
    { path: 'tour/filtrar', component: FindByTourComponent },
    { path: 'facturas/mis-facturas', component: MisFacturasUsuarioComponent },



    { path: '**', component: ErrorComponent }
];
