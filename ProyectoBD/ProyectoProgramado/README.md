# Sistema de Reservas de Tour

## Estructura de Base de Datos

### Archivos de Base de Datos
- `db/migration/20250101000000_init-schema.up.sql` - Estructura de tablas
- `db/triggers.sql` - Triggers de auditoría
- `db/test_auditoria.sql` - Script de prueba

### Cómo Configurar la Base de Datos

1. **Crear las tablas:**
   ```sql
   -- Ejecutar en SQL Server Management Studio
   -- db/migration/20250101000000_init-schema.up.sql
   ```

2. **Crear los triggers:**
   ```sql
   -- Ejecutar en SQL Server Management Studio
   -- db/triggers.sql
   ```

3. **Probar el sistema:**
   ```sql
   -- Ejecutar en SQL Server Management Studio
   -- db/test_auditoria.sql
   ```

## Configuración

### Archivo `app.env`
```env
DB_DRIVER=sqlserver
DB_SOURCE=sqlserver://localhost:1433?database=reservas_tour&trusted_connection=yes&encrypt=disable
SERVER_URL=127.0.0.1:8080
API_VERSION=api/v1
TOKEN_DURATION=15m
SYMMETRIC_KEY=12345678123456781234567812345678
```

## Sistema de Auditoría

El sistema incluye auditoría automática para:
- **Accesos a endpoints** - Registra TODOS los accesos a la API (GET, POST, PUT, DELETE)
- **Sesiones de usuario** - Registra inicio y fin de sesiones
- **Operaciones CRUD** - Registra cambios en reservas, facturas y usuarios

### Tablas de Auditoría
- `auditoria_accesos` - Registra accesos a endpoints (todos los métodos HTTP)
- `auditoria_sesiones` - Registra sesiones de usuario
- `auditoria_operaciones` - Registra operaciones CRUD
- `sesiones` - Maneja sesiones activas

### Verificar Auditoría
```sql
-- Ver todos los accesos
SELECT * FROM auditoria_accesos ORDER BY fechaAcceso DESC;

-- Ver accesos por usuario
SELECT userName, COUNT(*) as accesos FROM auditoria_accesos GROUP BY userName;

-- Ver endpoints más accedidos
SELECT endpoint, metodo, COUNT(*) as accesos FROM auditoria_accesos GROUP BY endpoint, metodo;
```

## Ejecutar el Sistema

```bash
# Compilar
go build -o main.exe main.go

# Ejecutar
./main.exe
```

## Endpoints Principales

- `POST /api/v1/login` - Iniciar sesión
- `POST /api/v1/logout` - Cerrar sesión
- `GET /api/v1/reserva` - Obtener reservas
- `POST /api/v1/reserva` - Crear reserva
- `GET /api/v1/factura` - Obtener facturas
- `POST /api/v1/factura` - Crear factura
