import { HttpInterceptorFn, HttpRequest, HttpHandlerFn, HttpEvent, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, catchError } from 'rxjs';
import Swal from 'sweetalert2';

export const authInterceptor: HttpInterceptorFn = (req: HttpRequest<unknown>, next: HttpHandlerFn): Observable<HttpEvent<unknown>> => {
  const token = sessionStorage.getItem('token');
  let authReq = req;

  if (token && !req.headers.has('Authorization')) {
    authReq = req.clone({
      setHeaders: { Authorization: `Bearer ${token}` }
    });
  }

  const router = inject(Router);

  return next(authReq).pipe(
    catchError((error: HttpErrorResponse) => {
      const errorMsg = error.error?.error?.toLowerCase() || '';
      const is403 = error.status === 403;
      const is401 = error.status === 401;
      const isAccessDenied = errorMsg.includes('acceso denegado') || 
                            errorMsg.includes('rol insuficiente') ||
                            errorMsg.includes('insufficient') ||
                            errorMsg.includes('forbidden');
      
      if (is401 || is403 || isAccessDenied) {
        Swal.fire({
          icon: 'error',
          title: 'Acceso denegado',
          text: 'No tienes permisos para acceder a esta sección. Por favor, inicia sesión con una cuenta autorizada.',
          confirmButtonText: 'Ir al login',
          confirmButtonColor: '#4e3e2e',
          allowOutsideClick: false,
          allowEscapeKey: false
        }).then(() => {
          sessionStorage.clear();
          router.navigate(['/login']);
        });
      }
      throw error;
    })
  );
};


