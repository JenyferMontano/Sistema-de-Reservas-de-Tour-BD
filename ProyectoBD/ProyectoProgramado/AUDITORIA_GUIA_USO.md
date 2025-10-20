# Guía de Uso del Sistema de Auditoría

## Descripción General

El sistema de auditoría registra automáticamente todas las actividades importantes en el sistema de reservas de tours, incluyendo:

- **Accesos a endpoints**: Quién accedió a qué endpoint y cuándo
- **Operaciones CRUD**: Creación, modificación y eliminación de registros
- **Sesiones de usuario**: Inicio y fin de sesiones
- **Información de seguridad**: IP, navegador, códigos de respuesta

## Tablas de Auditoría

### 1. `auditoria_accesos`
Registra todos los accesos a endpoints de la API.

**Campos:**
- `idAuditoria`: ID único
- `userName`: Usuario que accedió
- `endpoint`: Ruta accedida (ej: `/api/v1/tour`)
- `metodo`: Método HTTP (GET, POST, PUT, DELETE)
- `codigoRespuesta`: Código de respuesta HTTP (200, 400, 500, etc.)
- `fechaAcceso`: Fecha y hora del acceso
- `ipAddress`: Dirección IP del usuario
- `userAgent`: Información del navegador

### 2. `auditoria_operaciones`
Registra operaciones CRUD en las tablas principales.

**Campos:**
- `idAuditoria`: ID único
- `userName`: Usuario que realizó la operación
- `tablaAfectada`: Tabla modificada (reserva, factura, usuario)
- `operacion`: Tipo de operación (INSERT, UPDATE, DELETE)
- `registroId`: ID del registro afectado
- `valoresAnteriores`: Valores antes del cambio
- `valoresNuevos`: Valores después del cambio
- `fechaOperacion`: Fecha y hora de la operación
- `ipAddress`: IP del usuario

### 3. `auditoria_sesiones`
Registra inicio y fin de sesiones.

**Campos:**
- `idAuditoria`: ID único
- `userName`: Usuario de la sesión
- `fechaInicio`: Fecha de inicio de sesión
- `fechaFin`: Fecha de fin de sesión
- `ipAddress`: IP del usuario
- `userAgent`: Información del navegador
- `estado`: Estado de la sesión (ACTIVA, CERRADA, EXPIRADA)

### 4. `sesiones`
Maneja sesiones activas del sistema.

**Campos:**
- `sessionID`: ID único de sesión
- `userName`: Usuario de la sesión
- `fechaInicio`: Fecha de inicio
- `fechaFin`: Fecha de fin
- `ipAddress`: IP del usuario
- `userAgent`: Información del navegador
- `estado`: Estado de la sesión

## Consultas Útiles

### Ver actividad reciente
```sql
SELECT TOP 50 * FROM auditoria_accesos 
ORDER BY fechaAcceso DESC;
```

### Ver operaciones en reservas
```sql
SELECT * FROM auditoria_operaciones 
WHERE tablaAfectada = 'reserva' 
ORDER BY fechaOperacion DESC;
```

### Ver sesiones activas
```sql
SELECT * FROM sesiones 
WHERE estado = 'ACTIVA';
```

### Ver actividad de un usuario específico
```sql
SELECT * FROM auditoria_accesos 
WHERE userName = 'usuario123' 
ORDER BY fechaAcceso DESC;
```

### Ver accesos fallidos
```sql
SELECT * FROM auditoria_accesos 
WHERE codigoRespuesta >= 400 
ORDER BY fechaAcceso DESC;
```

## Triggers Automáticos

El sistema incluye 3 triggers que se ejecutan automáticamente:

1. **`tr_auditoria_reservas`**: Se activa en operaciones de la tabla `reserva`
2. **`tr_auditoria_facturas`**: Se activa en operaciones de la tabla `factura`
3. **`tr_auditoria_usuarios`**: Se activa en operaciones de la tabla `usuario`

## Middleware de Auditoría

### 1. `AuditMiddleware`
- Se ejecuta en todas las rutas
- Registra accesos a endpoints
- Captura información del usuario, IP, navegador

### 2. `LoginAuditMiddleware`
- Se ejecuta solo en `/login`
- Registra inicio de sesión
- Crea nueva sesión en la base de datos

### 3. `LogoutAuditMiddleware`
- Se ejecuta solo en `/logout`
- Registra fin de sesión
- Cierra sesión en la base de datos

### 4. `SessionValidationMiddleware`
- Valida sesiones activas
- Bloquea acceso si la sesión es inválida

## Configuración

### En `server.go`
```go
// Crear servicios de auditoría
auditService := services.NewAuditService(db)
sessionService := services.NewSessionService(db)

// Agregar middleware global
router.Use(middleware.AuditMiddleware(auditService))
router.Use(middleware.SessionValidationMiddleware(sessionService))

// Rutas con middleware específico
api.POST("/login", middleware.LoginAuditMiddleware(auditService, sessionService), usuarioHandler.Login)
api.POST("/logout", middleware.LogoutAuditMiddleware(auditService, sessionService), usuarioHandler.Logout)
```

## Monitoreo y Alertas

### Indicadores de Seguridad
- **Múltiples accesos fallidos**: Usuario con muchos códigos 401/403
- **Accesos desde IPs sospechosas**: IPs con mucha actividad
- **Operaciones fuera de horario**: Actividad en horarios inusuales
- **Sesiones largas**: Sesiones que duran más de lo normal

### Consultas de Monitoreo
```sql
-- Usuarios con más accesos fallidos
SELECT userName, COUNT(*) as fallos
FROM auditoria_accesos 
WHERE codigoRespuesta >= 400 
GROUP BY userName 
ORDER BY fallos DESC;

-- IPs con mucha actividad
SELECT ipAddress, COUNT(*) as accesos
FROM auditoria_accesos 
GROUP BY ipAddress 
HAVING COUNT(*) > 100
ORDER BY accesos DESC;
```

## Mantenimiento

### Limpieza de Datos Antiguos
```sql
-- Eliminar auditoría de más de 1 año
DELETE FROM auditoria_accesos 
WHERE fechaAcceso < DATEADD(YEAR, -1, GETDATE());

DELETE FROM auditoria_operaciones 
WHERE fechaOperacion < DATEADD(YEAR, -1, GETDATE());
```

### Optimización de Índices
```sql
-- Crear índices para mejorar rendimiento
CREATE INDEX IX_auditoria_accesos_userName ON auditoria_accesos(userName);
CREATE INDEX IX_auditoria_accesos_fechaAcceso ON auditoria_accesos(fechaAcceso);
CREATE INDEX IX_auditoria_operaciones_tablaAfectada ON auditoria_operaciones(tablaAfectada);
CREATE INDEX IX_auditoria_operaciones_fechaOperacion ON auditoria_operaciones(fechaOperacion);
```

## Ventajas del Sistema

1. **Automático**: No requiere cambios en el código existente
2. **Transparente**: Los usuarios no notan la auditoría
3. **Completo**: Registra todas las operaciones importantes
4. **Eficiente**: Usa triggers y middleware optimizados
5. **Flexible**: Fácil de consultar y analizar
6. **Seguro**: Registra información de seguridad (IP, navegador)

## Cumplimiento

El sistema cumple con los requisitos de auditoría:
- ✅ **3 tablas de auditoría** implementadas
- ✅ **3 triggers automáticos** para operaciones CRUD
- ✅ **Manejo de sesiones** completo
- ✅ **Control de acceso** con validación
- ✅ **Información vital** registrada (usuario, fecha, operación, IP)

## Notas Importantes

- Los triggers se ejecutan automáticamente en la base de datos
- Los middleware se ejecutan automáticamente en el servidor
- No es necesario modificar el código existente de los handlers
- La auditoría es completamente transparente para los usuarios
- Se puede consultar la auditoría usando las consultas SQL proporcionadas
