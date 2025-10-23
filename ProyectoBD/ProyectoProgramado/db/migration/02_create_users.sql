-- Script para crear usuarios del motor SQL Server
-- Este script debe ejecutarse como administrador de SQL Server

-- Crear login para usuario administrador
CREATE LOGIN usuario_admin WITH PASSWORD = 'AdminPass123!', 
    DEFAULT_DATABASE = reservas_tour,
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF;

-- Crear usuario en la base de datos para el administrador
USE reservas_tour;
CREATE USER usuario_admin FOR LOGIN usuario_admin;

-- Otorgar permisos completos al usuario administrador
ALTER ROLE db_owner ADD MEMBER usuario_admin;
GRANT CONTROL ON DATABASE::reservas_tour TO usuario_admin;

-- Crear login para usuario con permisos restringidos
CREATE LOGIN usuario_restringido WITH PASSWORD = 'RestrictedPass123!', 
    DEFAULT_DATABASE = reservas_tour,
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF;

-- Crear usuario en la base de datos para el usuario restringido
CREATE USER usuario_restringido FOR LOGIN usuario_restringido;

-- Otorgar permisos limitados al usuario restringido
-- Solo lectura en todas las tablas
GRANT SELECT ON SCHEMA::dbo TO usuario_restringido;

-- Permisos específicos para tablas de auditoría (solo lectura)
GRANT SELECT ON auditoria_sesiones TO usuario_restringido;
GRANT SELECT ON auditoria_operaciones TO usuario_restringido;
GRANT SELECT ON auditoria_accesos TO usuario_restringido;
GRANT SELECT ON sesiones TO usuario_restringido;

-- Permisos específicos para tablas principales (solo lectura)
GRANT SELECT ON persona TO usuario_restringido;
GRANT SELECT ON tour TO usuario_restringido;
GRANT SELECT ON usuario TO usuario_restringido;
GRANT SELECT ON reserva TO usuario_restringido;
GRANT SELECT ON factura TO usuario_restringido;
GRANT SELECT ON detallereserva TO usuario_restringido;
GRANT SELECT ON detallefactura TO usuario_restringido;

-- Crear roles personalizados para mejor organización
CREATE ROLE db_readonly;
CREATE ROLE db_auditor;

-- Asignar usuario restringido al rol de solo lectura
ALTER ROLE db_readonly ADD MEMBER usuario_restringido;

-- Crear usuario auditor (opcional)
CREATE LOGIN usuario_auditor WITH PASSWORD = 'AuditorPass123!', 
    DEFAULT_DATABASE = reservas_tour,
    CHECK_EXPIRATION = OFF,
    CHECK_POLICY = OFF;

CREATE USER usuario_auditor FOR LOGIN usuario_auditor;
ALTER ROLE db_auditor ADD MEMBER usuario_auditor;

-- Permisos para auditor (lectura en tablas de auditoría y algunas tablas principales)
GRANT SELECT ON auditoria_sesiones TO db_auditor;
GRANT SELECT ON auditoria_operaciones TO db_auditor;
GRANT SELECT ON auditoria_accesos TO db_auditor;
GRANT SELECT ON sesiones TO db_auditor;
GRANT SELECT ON usuario TO db_auditor;
GRANT SELECT ON persona TO db_auditor;

-- Verificar que los usuarios fueron creados correctamente
SELECT 
    name as 'Login Name',
    type_desc as 'Type',
    is_disabled as 'Disabled'
FROM sys.server_principals 
WHERE name IN ('usuario_admin', 'usuario_restringido', 'usuario_auditor');

-- Verificar usuarios en la base de datos
SELECT 
    dp.name as 'Database User',
    sp.name as 'Server Login',
    dp.type_desc as 'Type'
FROM sys.database_principals dp
LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
WHERE dp.name IN ('usuario_admin', 'usuario_restringido', 'usuario_auditor');