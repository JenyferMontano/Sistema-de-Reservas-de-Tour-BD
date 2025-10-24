# SQL Server User Integration - CORRECTED

## ⚠️ **IMPORTANTE: Separación de Roles**

Este sistema maneja **DOS NIVELES DE ROLES DISTINTOS** que NO deben mezclarse:

### 🔐 **Roles del Sistema (Aplicación)**
- **`admin`**: Acceso completo en la aplicación
- **`cliente`**: Acceso limitado en la aplicación
- **Usados por**: El middleware de autenticación y autorización del backend Go
- **Controlan**: El acceso a rutas y funcionalidades de la aplicación

### 🗄️ **Roles del Motor SQL Server (Base de Datos)**
- **`usuario_admin`**: Permisos de `db_owner` en SQL Server
- **`usuario_restringido`**: Permisos de solo lectura en SQL Server
- **`usuario_auditor`**: Permisos de auditoría en SQL Server
- **Usados por**: SQL Server para controlar acceso a la base de datos
- **Controlan**: Los permisos a nivel de base de datos

## 🎯 **Mapeo Correcto**

Los usuarios SQL Server se mapean a roles del sistema de la siguiente manera:

| Usuario SQL Server | Rol SQL Server | Rol Aplicación | Permisos Aplicación |
|-------------------|----------------|----------------|-------------------|
| `usuario_admin` | `db_owner` | `admin` | Acceso completo |
| `usuario_restringido` | `solo lectura` | `cliente` | Acceso limitado |
| `usuario_auditor` | `solo auditoría` | `cliente` | Acceso limitado |

## 🔧 **Implementación Correcta**

### ✅ **Lo que SÍ se modificó:**
1. **Login Handler**: Detecta usuarios SQL Server y los mapea a roles del sistema
2. **SQL Server Auth Service**: Maneja la autenticación de usuarios SQL Server
3. **Mapeo de Roles**: Convierte roles SQL Server a roles del sistema

### ❌ **Lo que NO se modificó:**
1. **Middleware de Autenticación**: Sigue manejando solo `admin` y `cliente`
2. **Middleware de Autorización**: Sigue usando los roles del sistema
3. **Rutas Protegidas**: Siguen usando `RequireRole("admin")` o `RequireRole("cliente")`
4. **Sistema de Tokens**: Sigue funcionando igual
5. **Configuración**: `config.go` y `app.env` no se modificaron

## 🚀 **Cómo Funciona**

### **Flujo de Autenticación:**

1. **Usuario envía login** con email y password
2. **Sistema detecta** si es usuario SQL Server o usuario de aplicación
3. **Si es SQL Server**:
   - Valida credenciales contra usuarios SQL Server
   - Mapea el rol SQL Server a rol del sistema
   - Crea token con rol del sistema (`admin` o `cliente`)
4. **Si es aplicación**:
   - Valida contra tabla `Usuario` (flujo normal)
   - Crea token con rol del sistema
5. **Middleware existente** valida el token usando roles del sistema

### **Ejemplos de Login:**

#### **Usuario SQL Server (Admin):**
```json
POST /api/v1/login
{
  "email": "usuario_admin@sqlserver.local",
  "password": "AdminPass123!"
}
```
**Resultado**: Token con rol `admin` (acceso completo)

#### **Usuario SQL Server (Cliente):**
```json
POST /api/v1/login
{
  "email": "usuario_restringido@sqlserver.local",
  "password": "RestrictedPass123!"
}
```
**Resultado**: Token con rol `cliente` (acceso limitado)

#### **Usuario de Aplicación:**
```json
POST /api/v1/login
{
  "email": "user@example.com",
  "password": "userpassword"
}
```
**Resultado**: Token con rol del usuario en la tabla `Usuario`

## 🔑 **Credenciales SQL Server**

| Usuario | Email | Password | Rol Aplicación |
|---------|-------|----------|----------------|
| `usuario_admin` | `usuario_admin@sqlserver.local` | `AdminPass123!` | `admin` |
| `usuario_restringido` | `usuario_restringido@sqlserver.local` | `RestrictedPass123!` | `cliente` |
| `usuario_auditor` | `usuario_auditor@sqlserver.local` | `AuditorPass123!` | `cliente` |

## ✅ **Ventajas de esta Implementación**

1. **No rompe nada existente**: El middleware y rutas siguen funcionando igual
2. **Separación clara**: Roles SQL Server vs roles de aplicación
3. **Compatibilidad**: Usuarios existentes siguen funcionando
4. **Flexibilidad**: Los permisos SQL Server se manejan a nivel de base de datos
5. **Mantenibilidad**: Código limpio y fácil de entender

## 🧪 **Testing**

Para probar la integración:

```bash
# Iniciar servidor
go run main.go

# Probar usuario SQL Server admin
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email": "usuario_admin@sqlserver.local", "password": "AdminPass123!"}'

# Probar usuario SQL Server cliente
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email": "usuario_restringido@sqlserver.local", "password": "RestrictedPass123!"}'
```

## 📋 **Resumen**

- ✅ **Roles SQL Server**: Solo para permisos de base de datos
- ✅ **Roles del Sistema**: Solo para control de acceso en la aplicación
- ✅ **Middleware**: No modificado, sigue manejando `admin` y `cliente`
- ✅ **Login**: Detecta y mapea usuarios SQL Server a roles del sistema
- ✅ **Compatibilidad**: Usuarios existentes siguen funcionando igual
