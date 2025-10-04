-- name: CreateUsuario :execresult
INSERT INTO Usuario (userName, password, rol, idPersona, image)
VALUES (?, ?, ?, ?, ?);

-- name: GetUsuarioByUserName :one
SELECT userName, password, rol, idPersona, image
FROM Usuario
WHERE userName = ?;

-- name: UpdateUsuario :exec
UPDATE Usuario
SET password = ?, image = ?
WHERE userName = ?;

-- name: DeleteUsuario :exec
DELETE FROM Usuario
WHERE userName = ?;

-- name: GetAllUsuarios :many
SELECT userName, rol, idPersona, image
FROM Usuario;

-- name: UsuarioExiste :one
SELECT COUNT(*) as count
FROM Usuario
WHERE userName = ?;


-- name: GetCorreoByUserName :one
SELECT p.correo
FROM Usuario u
JOIN Persona p ON u.idPersona = p.idPersona
WHERE u.userName = ?;

-- name: GetUsuarioByCorreo :one
SELECT u.userName, u.password, u.rol, u.idPersona, u.image
FROM Usuario u
JOIN Persona p ON u.idPersona = p.idPersona
WHERE p.correo = ?;
