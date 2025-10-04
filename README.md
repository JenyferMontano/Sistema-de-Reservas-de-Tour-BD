# Sistema-de-Reservas-de-Tour-BD
Este sistema fue desarrollado como parte del curso Administración de Bases de Datos, con el objetivo de aplicar buenas prácticas de diseño e implementación de sistemas basados en bases de datos relacionales.  La aplicación permite gestionar de forma completa el proceso de reservas de tours en un hotel.
La aplicación permite gestionar de forma completa el proceso de reservas de tours en un hotel, abarcando desde la administración de tours disponibles hasta la generación de facturas para los clientes.

#🚀 Funcionalidades principales
- Gestión de Tours: creación, edición, eliminación y consulta de tours disponibles.
- Reservas: registro y control de reservas asociadas a los clientes y a los tours.
- Usuarios: administración de usuarios y roles del sistema (clientes, administradores, etc.).
- Facturación: generación automática de facturas basadas en las reservas confirmadas.
- Seguridad: manejo de usuarios autenticados, contraseñas seguras y validaciones de datos.

#Tecnologías utilizadas
- Base de datos: Microsoft SQL Server (procedimientos almacenados, triggers y consultas SQL).
- Backend: Go (Golang) con arquitectura modular y conexión directa a procedimientos almacenados.
- Frontend: Angular con consumo de API REST y manejo de formularios reactivos.
- ORM / DB Access: database/sql con sentencias parametrizadas para mayor seguridad.
