-- name: CreateAuditoriaAcceso :exec
INSERT INTO auditoria_accesos (userName, endpoint, metodo, codigoRespuesta, ipAddress, userAgent)
VALUES (?, ?, ?, ?, ?, ?);

-- name: CreateAuditoriaOperacion :exec
INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress)
VALUES (?, ?, ?, ?, ?, ?, ?);

-- name: CreateAuditoriaSesion :exec
INSERT INTO auditoria_sesiones (userName, fechaInicio, ipAddress, userAgent, estado)
VALUES (?, ?, ?, ?, ?);

-- name: UpdateAuditoriaSesion :exec
UPDATE auditoria_sesiones
SET fechaFin = ?, estado = ?
WHERE userName = ? AND estado = 'ACTIVA';

-- name: GetAuditoriaAccesos :many
SELECT 
    idAuditoria,
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress,
    userAgent
FROM auditoria_accesos
WHERE userName = ?
ORDER BY fechaAcceso DESC;

-- name: GetAuditoriaOperaciones :many
SELECT 
    idAuditoria,
    userName,
    tablaAfectada,
    operacion,
    registroId,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion,
    ipAddress
FROM auditoria_operaciones
WHERE userName = ?
ORDER BY fechaOperacion DESC;

-- name: GetAuditoriaSesiones :many
SELECT 
    idAuditoria,
    userName,
    fechaInicio,
    fechaFin,
    ipAddress,
    userAgent,
    estado
FROM auditoria_sesiones
WHERE userName = ?
ORDER BY fechaInicio DESC;

-- name: GetAuditoriaOperacionesByTabla :many
SELECT 
    idAuditoria,
    userName,
    tablaAfectada,
    operacion,
    registroId,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion,
    ipAddress
FROM auditoria_operaciones
WHERE tablaAfectada = ?
ORDER BY fechaOperacion DESC;

-- name: GetAuditoriaAccesosByEndpoint :many
SELECT 
    idAuditoria,
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress,
    userAgent
FROM auditoria_accesos
WHERE endpoint = ?
ORDER BY fechaAcceso DESC;

-- name: GetAuditoriaSesionesActivas :many
SELECT 
    idAuditoria,
    userName,
    fechaInicio,
    ipAddress,
    userAgent,
    estado
FROM auditoria_sesiones
WHERE estado = 'ACTIVA'
ORDER BY fechaInicio DESC;

-- name: GetAuditoriaOperacionesByFecha :many
SELECT 
    idAuditoria,
    userName,
    tablaAfectada,
    operacion,
    registroId,
    valoresAnteriores,
    valoresNuevos,
    fechaOperacion,
    ipAddress
FROM auditoria_operaciones
WHERE fechaOperacion BETWEEN ? AND ?
ORDER BY fechaOperacion DESC;

-- name: GetAuditoriaAccesosByFecha :many
SELECT 
    idAuditoria,
    userName,
    endpoint,
    metodo,
    codigoRespuesta,
    fechaAcceso,
    ipAddress,
    userAgent
FROM auditoria_accesos
WHERE fechaAcceso BETWEEN ? AND ?
ORDER BY fechaAcceso DESC;
