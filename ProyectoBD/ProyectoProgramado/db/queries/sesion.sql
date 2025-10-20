-- name: CreateSession :exec
INSERT INTO sesiones (sessionID, userName, ipAddress, userAgent, estado)
VALUES (?, ?, ?, ?, ?);

-- name: ValidateSession :one
SELECT COUNT(*) as count
FROM sesiones
WHERE sessionID = ? AND estado = 'ACTIVA';

-- name: CloseSession :exec
UPDATE sesiones
SET fechaFin = ?, estado = ?
WHERE sessionID = ?;

-- name: GetSessionByID :one
SELECT 
    sessionID,
    userName,
    fechaInicio,
    fechaFin,
    ipAddress,
    userAgent,
    estado
FROM sesiones
WHERE sessionID = ?;

-- name: GetSessionsByUser :many
SELECT 
    sessionID,
    userName,
    fechaInicio,
    fechaFin,
    ipAddress,
    userAgent,
    estado
FROM sesiones
WHERE userName = ?
ORDER BY fechaInicio DESC;

-- name: GetActiveSessions :many
SELECT 
    sessionID,
    userName,
    fechaInicio,
    ipAddress,
    userAgent,
    estado
FROM sesiones
WHERE estado = 'ACTIVA'
ORDER BY fechaInicio DESC;

-- name: CloseAllUserSessions :exec
UPDATE sesiones
SET fechaFin = GETDATE(), estado = 'CERRADA'
WHERE userName = ? AND estado = 'ACTIVA';

-- name: GetSessionByUserAndIP :one
SELECT 
    sessionID,
    userName,
    fechaInicio,
    fechaFin,
    ipAddress,
    userAgent,
    estado
FROM sesiones
WHERE userName = ? AND ipAddress = ? AND estado = 'ACTIVA';

-- name: CleanExpiredSessions :exec
UPDATE sesiones
SET fechaFin = GETDATE(), estado = 'EXPIRADA'
WHERE estado = 'ACTIVA' AND fechaInicio < DATEADD(hour, -24, GETDATE());
