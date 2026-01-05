# Sistema de Reservas de Tours
Aplicación web full stack desarrollada como proyecto del curso Administración de Bases de Datos. El sistema centraliza la operación de reservas de tours para un hotel: publica las experiencias disponibles, gestiona clientes, controla reservas, genera facturación y mantiene trazabilidad de accesos, todo respaldado por una base de datos SQL Server alojada en Azure.

## 🚀 Funcionalidades principales
- Gestión de tours: creación, edición, eliminación y consulta de experiencias disponibles.
- Reservas: registro, seguimiento y cancelación de reservas asociadas a cada cliente.
- Usuarios y roles: administración de cuentas con control de permisos para administradores y huéspedes.
- Facturación: generación y descarga de comprobantes basados en las reservas confirmadas.
- Auditoría y seguridad: autenticación, manejo seguro de sesiones y registro de acciones relevantes.

## 🛠️ Tecnologías utilizadas
- Base de datos: Microsoft SQL Server (procedimientos almacenados, triggers, consultas parametrizadas).
- Backend: Go (Golang) con arquitectura modular y acceso directo a procedimientos almacenados.
- Frontend: Angular con consumo de API REST y formularios reactivos.
- Infraestructura: Azure SQL Database para el entorno gestionado en la nube.

## ✅ Requisitos previos
- Go 1.22 o superior.
- Node.js 18 LTS (incluye npm).
- Angular CLI instalado globalmente (`npm install -g @angular/cli`).
- Archivo `app.env` con las variables de entorno requeridas por el backend (cadena de conexión a SQL Server, configuración de tokens y puertos).

## ▶️ Puesta en marcha local
El proyecto asume que la base de datos ya está desplegada en Azure y accesible a través de las credenciales configuradas en `app.env`.

**Backend (Go)**
1. Abrir una terminal y ubicarse en `ProyectoBD/ProyectoProgramado`.
2. Verificar que `.env` contenga las variables necesarias
3. Ejecutar el servidor:
   ```bash
   go run main.go
   ```

**Frontend (Angular)**
1. Abrir una segunda terminal y ubicarse en `ProyectoIFront`.
2. Instalar dependencias (solo la primera vez o cuando cambie `package.json`):
   ```bash
   npm install
   ```
3. Levantar el servidor de desarrollo:
   ```bash
   ng serve
   ```
   El frontend queda disponible en `http://localhost:4200/`. Si se desea generar un build de producción: `ng build --configuration production`.

## 🌐 Enlace a la versión desplegada
https://sistema-de-reservas-de-tour-bd-f.onrender.com

## 🔐 Credenciales de prueba
- Email administrador: `admin@sistema.com`
- Contraseña administrador: `admin123`
