import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { authInterceptor } from './services/auth.interceptor';

import { routes } from './app.routes';

const LOCAL_API = 'http://127.0.0.1:8080/api/v1';
const PROD_API = 'https://sistema-de-reservas-de-tour-bd-chw7.onrender.com/api/v1';

export const API_BASE =
  (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? LOCAL_API
    : PROD_API;


export const appConfig: ApplicationConfig = {
   providers: [
    provideZoneChangeDetection({ eventCoalescing: true }), 
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};
