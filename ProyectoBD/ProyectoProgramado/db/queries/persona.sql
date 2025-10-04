-- name: GetAllPersonas :many
SELECT * FROM persona;

-- name: GetPersonaById :one
SELECT TOP 1 * FROM persona WHERE idPersona = @idPersona;

-- name: CreatePersona :execresult
INSERT INTO persona (nombre, apellido_1, apellido_2, fechaNac, direccion, telefono, correo)
VALUES (@nombre, @apellido_1, @apellido_2, @fechaNac, @direccion, @telefono, @correo);

-- name: UpdatePersona :exec
UPDATE persona
SET nombre = @nombre, apellido_1 = @apellido_1, apellido_2 = @apellido_2, fechaNac = @fechaNac, direccion = @direccion, telefono = @telefono, correo = @correo
WHERE idPersona = @idPersona;

-- name: DeletePersona :exec
DELETE FROM persona WHERE idPersona = @idPersona;


