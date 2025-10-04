SELECT * FROM Tour;

SELECT TOP 1 * FROM Tour WHERE idTour = @idTour;

SELECT TOP 1 precioBase FROM Tour WHERE idTour = @idTour;

SELECT * FROM Tour WHERE tipo = @tipo;

INSERT INTO Tour (nombre, descripcion, tipo, disponibilidad, precioBase, ubicacion, imageTour)
OUTPUT INSERTED.idTour
VALUES (@nombre, @descripcion, @tipo, @disponibilidad, @precioBase, @ubicacion, @imageTour);

UPDATE Tour
SET nombre = @nombre, descripcion = @descripcion, tipo = @tipo, disponibilidad = @disponibilidad, precioBase = @precioBase, ubicacion = @ubicacion, imageTour = @imageTour
WHERE idTour = @idTour;

DELETE FROM Tour WHERE idTour = @idTour;