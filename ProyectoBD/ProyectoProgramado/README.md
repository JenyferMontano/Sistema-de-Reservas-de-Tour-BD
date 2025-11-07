# Sistema de Reservas de Tour

API REST construida en Go para la gestión de tours, reservas, facturación y operaciones administrativas sobre una base de datos SQL Server (probada con Azure SQL Database). El proyecto implementa autenticación con tokens PASETO, auditoría de accesos y operaciones, generación de facturas en PDF y un módulo de respaldo/restauración orientado al rol DBA.

## Tecnologías y componentes
- Go 1.24 + Gin (`github.com/gin-gonic/gin`) para exponer la API.
- SQL Server / Azure SQL Database como motor de datos.
- `sqlc` para generar capa de acceso a datos sobre procedimientos almacenados.
- PASETO (`github.com/o1egl/paseto`) para emisión de tokens.
- Servicios de auditoría y sesiones que consumen stored procedures (`sp_log_*`, `sp_create_session`, etc.).
- Generación de PDF de facturas con `github.com/jung-kurt/gofpdf`.
- Dockerfile multietapa para empaquetar la API.

## Requisitos previos
- Go ≥ 1.22 (el proyecto se compila con Go 1.24).
- SQL Server 2019+ o Azure SQL Database.
- Herramienta de administración SQL (Azure Data Studio, SSMS o `sqlcmd`).
- Acceso a un almacenamiento compatible con Windows si se usará generación de PDF con imágenes en rutas absolutas.
- (Opcional) `sqlc` 1.29+ si se desean regenerar los archivos en `dto/`.

## Preparar la base de datos
1. Crear la base de datos `reservas_tour` en el servidor deseado.
2. Ejecutar el script de estructura `db/migration/20250101000000_init-schema.up.sql`.
3. Crear los **procedimientos almacenados y vistas** que consume la aplicación. Deben existir, entre otros:
   - **Catálogos**: `pa_persona_*`, `pa_tour_*`, `pa_usuario_*`.
   - **Reservas y detalle**: `pa_reserva_*`, `pa_detalleReserva_*`, `pa_detallefactura_*`, `pa_factura_*`.
   - **Sesiones y auditoría**: `sp_log_access`, `sp_log_operation`, `sp_log_session_start`, `sp_log_session_end`, `sp_log_session_end_by_id`, `sp_create_session`, `sp_validate_session`, `sp_close_session`, `sp_close_all_user_sessions`, `sp_get_active_sessions`, `sp_set_session_context`.
   - **Respaldos**: `sp_respaldo_reservas_tour`, `sp_restaurar_reservas_tour`, `sp_listar_respaldos_reservas_tour`, vistas de auditoría DBA.
4. Poblar datos de referencia (personas, tours, usuarios) según las necesidades del entorno.
5. Para revertir la estructura en entornos de prueba está disponible `db/migration/20250101000000_init-schema.down.sql`.

> ℹ️ El repositorio no incluye los scripts de procedimientos almacenados. Si trabajas con Azure SQL Database, coordina con el DBA para cargarlos o mantenlos en un repositorio privado.

## Variables de entorno (`app.env`)
La aplicación utiliza `viper` y espera encontrar un archivo `app.env` en el directorio raíz.

```env
DB_DRIVER=sqlserver
DB_SOURCE=sqlserver://<usuario>:<contraseña>@<host>?database=<nombre_bd>&encrypt=disable
SERVER_URL=127.0.0.1:8080
API_VERSION=api/v1
TOKEN_DURATION=15m
SYMMETRIC_KEY=12345678123456781234567812345678
```

- `DB_SOURCE`: usa el formato de conexión compatible con `github.com/microsoft/go-mssqldb`. Ajusta opciones como `encrypt=disable/true`, `trustservercertificate=true`, etc. según tu servidor.
- `TOKEN_DURATION`: duración de los tokens de acceso (formato Go, por ejemplo `15m`, `1h`).
- `SYMMETRIC_KEY`: llave de 32 bytes requerida por PASETO. Actualmente `api/server.go` utiliza un valor fijo; si lo cambias aquí, actualiza también la llamada a `security.NewPasetoBuilder`.
- No subas `app.env` con credenciales reales al control de versiones.

## Ejecutar la API
1. Instalar dependencias:
   ```bash
   go mod download
   ```
2. Verificar conexión a la base de datos configurada en `app.env`.
3. Ejecutar en modo desarrollo:
   ```bash
   go run main.go
   ```
4. (Opcional) Compilar binario:
   ```bash
   go build -o bin/api main.go
   ./bin/api
   ```

### Contenedor Docker
```bash
docker build -t reservas-tour .
docker run --rm -p 8080:8080 --env-file app.env reservas-tour
```
Asegúrate de montar o copiar un `app.env` sin credenciales sensibles antes de construir la imagen si planeas publicarla.

## Estructura relevante
- `api/`: handlers, routers y middlewares por módulo (persona, tour, usuario, reserva, factura, respaldo, etc.).
- `services/`: reglas de negocio transversales (auditoría, sesiones, login SQL Server simulado).
- `dto/`: código generado por `sqlc` que envuelve procedimientos almacenados.
- `security/`: creación y verificación de tokens PASETO.
- `utils/images/`: almacenamiento local de imágenes para usuarios, tours y facturas (usadas al generar PDFs o servir assets).

## Endpoints destacados (`/api/v1`)
- **Autenticación**
  - `POST /login` – genera token PASETO. Retorna header `x-session-id` cuando la auditoría crea una nueva sesión.
  - `POST /logout` – cierra la sesión actual y registra auditoría.
- **Personas** (`/persona`)
  - `GET /` listar, `GET /:id`, `POST /`, `PUT /:id`, `DELETE /:id`.
- **Usuarios** (`/usuario`)
  - CRUD básico, subida de imágenes (`POST /upload`), descarga (`GET /img/:name`).
- **Tours** (`/tour`)
  - CRUD y consulta por tipo, entrega de imágenes `GET /img/:name`.
- **Reservas** (`/reserva`)
  - `POST /crear` (crea reserva con detalles), listados, búsqueda por usuario/huesped, actualización de estado y eliminación.
- **Facturas** (`/factura`)
  - CRUD, búsqueda por persona/reserva y `GET /:id/pdf` para generar el PDF.
- **Detalle de factura / reserva**
  - Endpoints de consulta y mantenimiento específicos.
- **Respaldos (solo rol DBA)**
  - `POST /respaldo/respaldo`, `POST /respaldo/restaurar`, `POST /respaldo/respaldos`, `GET /respaldo/auditoria`.

Todas las rutas (excepto login y recursos públicos de imágenes) esperan el header `Authorization: Bearer <token>`.

## Autenticación y manejo de sesiones
- `services/sqlserver_auth.go` contiene credenciales de prueba para usuarios tipo SQL Server (`usuario_admin`, `usuario_restringido`). Se autentican con email `@sqlserver.local`.
- Usuarios de la aplicación se validan contra la tabla `usuario`.
- Tras un login exitoso se dispara `LoginAuditMiddleware`: registra auditoría, crea sesión (`sp_create_session`) e inserta cabecera `x-session-id`.
- `SessionValidationMiddleware` verifica que la sesión siga activa antes de ejecutar la mayoría de endpoints.
- `LogoutAuditMiddleware` registra el cierre de sesión y marca las sesiones como finalizadas.

## Auditoría
- **Tablas principales**: `auditoria_accesos`, `auditoria_sesiones`, `auditoria_operaciones`, `sesiones`.
- **Servicios**: `services.AuditService` expone métodos que llaman procedimientos `sp_log_*`.
- Los middlewares registran automáticamente IP, user-agent, endpoint y código de respuesta.
- Para validar la información, ejecuta consultas como:
  ```sql
  SELECT TOP 50 * FROM auditoria_accesos ORDER BY fechaAcceso DESC;
  SELECT TOP 50 * FROM auditoria_operaciones ORDER BY fechaOperacion DESC;
  ```

## Módulo de respaldo y restauración
- Implementado en `api/respaldo` y `dto/respaldo.sql.go`.
- Requiere stored procedures `sp_respaldo_reservas_tour`, `sp_restaurar_reservas_tour`, `sp_listar_respaldos_reservas_tour` y vistas de auditoría para el historial DBA.
- Solo usuarios con rol `DBA` pueden invocar los endpoints.
- Las operaciones retornan estructuras con estado (`EXITOSO` / `ERROR`), mensajes y tiempos de ejecución.

## Generación de facturas en PDF
- `api/factura/generatorPDF.go` construye un PDF estilizado con `gofpdf`.
- El archivo usa rutas absolutas de Windows para el logo (`utils/images/factura_logo/logitoFactura.png`). Ajusta `logoPath` según el despliegue (idealmente conviértelo en configuración).
- Los textos se transforman a Latin-1 para evitar problemas con acentos al generar el PDF.

## Imágenes y archivos estáticos
- Imágenes cargadas por usuarios se guardan en `utils/images/usuarios`.
- Las imágenes de tours y facturas están en `utils/images/tour` y `utils/images/factura_logo`.
- Asegúrate de que el directorio tenga permisos de escritura si despliegas en otro entorno. Las rutas se sirven mediante endpoints (p. ej. `GET /api/v1/tour/img/:name`).

## Desarrollo y mantenimiento
- Ejecuta `sqlc generate` después de actualizar consultas/procedimientos y los archivos `.sql` dentro de `db/`. Ajusta `sqlc.yaml` si mueves las rutas.
- No existe suite de pruebas automatizadas; prueba manualmente los flujos críticos (login, creación de reserva y factura, generación de PDF, endpoints DBA).
- Mantén sincronizados los valores de `SYMMETRIC_KEY` entre `app.env` y `api/server.go`.
- Considera extraer los secretos y rutas absolutas a variables de entorno antes de desplegar en producción.

## Solución de problemas
- **`No se puede establecer la conexión`**: revisa `DB_SOURCE`, puertos y firewall del servidor SQL.
- **`Duración del token inválida`**: verifica el formato de `TOKEN_DURATION`.
- **Sesión inválida**: confirma que `sp_create_session` y procedimientos relacionados existan y que `SessionValidationMiddleware` pueda consultarlos.
- **Generación de PDF falla**: valida que `logoPath` exista y que la aplicación tenga permisos de lectura.
- **Errores en auditoría o respaldo**: revisa que todos los procedimientos almacenados requeridos estén desplegados y el usuario tenga permisos para ejecutarlos.

---

Mantén este documento actualizado cuando se agreguen nuevos módulos, endpoints o scripts de base de datos. Cualquier detalle específico del despliegue (Azure, on-premise, contenedores) debería documentarse en secciones adicionales o anexos privados.
