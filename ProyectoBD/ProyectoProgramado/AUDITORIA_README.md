# Sistema de Auditoría - Proyecto Reservas Tour

## Descripción
Este documento describe el sistema de auditoría implementado en el proyecto de reservas de tours. El sistema registra automáticamente todas las operaciones realizadas por los usuarios del sistema.

## Componentes del Sistema de Auditoría

### 1. Tablas de Auditoría

#### `auditoria_sesiones`
Registra el inicio y fin de sesiones de usuarios:
- **idAuditoria**: Identificador único
- **userName**: Nombre de usuario
- **fechaInicio**: Fecha y hora de inicio de sesión
- **fechaFin**: Fecha y hora de fin de sesión
- **ipAddress**: Dirección IP del usuario
- **userAgent**: Información del navegador
- **estado**: Estado de la sesión (ACTIVA, CERRADA, EXPIRADA)

#### `auditoria_operaciones`
Registra operaciones CRUD en las tablas principales:
- **idAuditoria**: Identificador único
- **userName**: Usuario que realizó la operación
- **tablaAfectada**: Tabla que fue modificada
- **operacion**: Tipo de operación (INSERT, UPDATE, DELETE)
- **registroId**: ID del registro afectado
- **valoresAnteriores**: Valores antes del cambio
- **valoresNuevos**: Valores después del cambio
- **fechaOperacion**: Fecha y hora de la operación
- **ipAddress**: IP del usuario

#### `auditoria_accesos`
Registra accesos a endpoints de la API:
- **idAuditoria**: Identificador único
- **userName**: Usuario que accedió
- **endpoint**: Endpoint accedido
- **metodo**: Método HTTP (GET, POST, PUT, DELETE)
- **codigoRespuesta**: Código de respuesta HTTP
- **fechaAcceso**: Fecha y hora del acceso
- **ipAddress**: IP del usuario
- **userAgent**: Información del navegador

#### `sesiones`
Maneja sesiones activas del sistema:
- **sessionID**: Identificador único de sesión
- **userName**: Usuario de la sesión
- **fechaInicio**: Fecha de inicio
- **fechaFin**: Fecha de fin
- **ipAddress**: IP del usuario
- **userAgent**: Información del navegador
- **estado**: Estado de la sesión

### 2. Triggers Automáticos

#### `tr_auditoria_reservas`
Se ejecuta automáticamente cuando se realizan operaciones en la tabla `reserva`:
- Registra INSERT, UPDATE, DELETE
- Captura información del usuario y cambios realizados

#### `tr_auditoria_facturas`
Se ejecuta automáticamente cuando se realizan operaciones en la tabla `factura`:
- Registra INSERT, UPDATE, DELETE
- Captura información del usuario y cambios realizados

#### `tr_auditoria_usuarios`
Se ejecuta automáticamente cuando se realizan operaciones en la tabla `usuario`:
- Registra INSERT, UPDATE, DELETE
- Captura información del usuario y cambios realizados

### 3. Servicios de Auditoría

#### `AuditService`
Servicio principal para registrar auditoría:
- `LogAccess()`: Registra accesos a endpoints
- `LogOperation()`: Registra operaciones CRUD
- `LogSessionStart()`: Registra inicio de sesión
- `LogSessionEnd()`: Registra fin de sesión

#### `SessionService`
Servicio para manejo de sesiones:
- `CreateSession()`: Crear nueva sesión
- `ValidateSession()`: Validar sesión activa
- `CloseSession()`: Cerrar sesión

### 4. Middleware de Auditoría

#### `AuditMiddleware`
Middleware que se ejecuta en todas las rutas para registrar accesos:
- Captura información del request
- Registra en `auditoria_accesos`
- Se ejecuta automáticamente

#### `SessionValidationMiddleware`
Middleware para validar sesiones:
- Verifica si la sesión está activa
- Bloquea acceso si la sesión es inválida

#### `LoginAuditMiddleware`
Middleware para login:
- Registra inicio de sesión
- Crea nueva sesión en la base de datos

#### `LogoutAuditMiddleware`
Middleware para logout:
- Registra fin de sesión
- Cierra sesión en la base de datos

## Integración en el Código

### 1. En `server.go`

```go
// Importar servicios
import (
    "ProyectoProgramadoI/services"
    "ProyectoProgramadoI/api/middleware"
)

// Crear servicios
auditService := services.NewAuditService(db)
sessionService := services.NewSessionService(db)

// Agregar middleware global
router.Use(middleware.AuditMiddleware(auditService))
router.Use(middleware.SessionValidationMiddleware(sessionService))

// Para rutas de login
router.POST("/login", middleware.LoginAuditMiddleware(auditService, sessionService), loginHandler)

// Para rutas de logout
router.POST("/logout", middleware.LogoutAuditMiddleware(auditService, sessionService), logoutHandler)
```

### 2. En los Handlers

Los handlers no necesitan cambios. La auditoría se ejecuta automáticamente a través de los middleware.

### 3. Consultas de Auditoría

Para consultar la auditoría, puedes usar las tablas directamente:

```sql
-- Ver accesos de un usuario
SELECT * FROM auditoria_accesos WHERE userName = 'usuario123';

-- Ver operaciones en una tabla
SELECT * FROM auditoria_operaciones WHERE tablaAfectada = 'reserva';

-- Ver sesiones activas
SELECT * FROM sesiones WHERE estado = 'ACTIVA';

-- Ver auditoría de sesiones
SELECT * FROM auditoria_sesiones WHERE userName = 'usuario123';
```

## Qué se Audita Automáticamente

### Operaciones CRUD (Triggers)
- ✅ **Creación de reservas** - Quién, cuándo, qué datos
- ✅ **Modificación de reservas** - Cambios de estado, totales
- ✅ **Eliminación de reservas** - Quién eliminó qué
- ✅ **Creación de facturas** - Quién, cuándo, montos
- ✅ **Modificación de facturas** - Cambios de estado, pagos
- ✅ **Gestión de usuarios** - Creación, modificación, eliminación

### Accesos a la API (Middleware)
- ✅ **Todos los endpoints** - Qué usuario accedió a qué endpoint
- ✅ **Métodos HTTP** - GET, POST, PUT, DELETE
- ✅ **Códigos de respuesta** - 200, 400, 500, etc.
- ✅ **Información del cliente** - IP, navegador, fecha/hora

### Sesiones de Usuario (Middleware)
- ✅ **Inicio de sesión** - Cuándo y desde dónde
- ✅ **Fin de sesión** - Cuándo se cerró
- ✅ **Sesiones activas** - Quién está conectado ahora
- ✅ **Validación de sesiones** - Verificar si la sesión es válida

## Ventajas del Sistema

1. **Automático**: No requiere cambios en el código existente
2. **Transparente**: Los usuarios no notan la auditoría
3. **Completo**: Registra todas las operaciones importantes
4. **Eficiente**: Usa triggers y middleware optimizados
5. **Flexible**: Fácil de consultar y analizar

## Cumplimiento con Requisitos

- ✅ **3 tablas de auditoría** - `auditoria_sesiones`, `auditoria_operaciones`, `auditoria_accesos`
- ✅ **3 triggers automáticos** - Para reservas, facturas y usuarios
- ✅ **Manejo de sesiones** - Creación, validación y cierre
- ✅ **Control de acceso** - Validación en cada request
- ✅ **Información vital** - Usuario, fecha, operación, tabla, IP

## Notas Importantes

- Los triggers se ejecutan automáticamente en la base de datos
- Los middleware se ejecutan automáticamente en el servidor
- No es necesario modificar el código existente de los handlers
- La auditoría es completamente transparente para los usuarios
- Se puede consultar la auditoría usando las vistas y tablas creadas
