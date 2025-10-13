package dto

import (
	"database/sql"
)

// Funciones CRUD para Tour usando SQL Server

func CreateTour(db *sql.DB, t Tour) error {
	_, err := db.Exec(
		`EXEC pa_tour_insert 
		 @nombre=@p1, 
		 @descripcion=@p2, 
		 @tipo=@p3, 
		 @disponibilidad=@p4, 
		 @precioBase=@p5, 
		 @ubicacion=@p6, 
		 @imageTour=@p7`,
		t.Nombre, t.Descripcion, t.Tipo, t.Disponibilidad, t.Preciobase, t.Ubicacion, t.Imagetour,
	)
	return err
}

func DeleteTour(db *sql.DB, id int32) error {
	_, err := db.Exec("EXEC pa_tour_delete @idTour=@p1", id)
	return err
}

func GetAllTours(db *sql.DB) ([]Tour, error) {
	rows, err := db.Query("EXEC pa_tour_getAll")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tours []Tour
	for rows.Next() {
		var t Tour
		err := rows.Scan(&t.Idtour, &t.Nombre, &t.Descripcion, &t.Tipo, &t.Disponibilidad, &t.Preciobase, &t.Ubicacion, &t.Imagetour)
		if err != nil {
			return nil, err
		}
		tours = append(tours, t)
	}

	return tours, nil
}

func GetTourById(db *sql.DB, id int32) (*Tour, error) {
	row := db.QueryRow(
		"EXEC pa_tour_getById @idTour=@p1",
		id,
	)
	var t Tour
	err := row.Scan(&t.Idtour, &t.Nombre, &t.Descripcion, &t.Tipo, &t.Disponibilidad, &t.Preciobase, &t.Ubicacion, &t.Imagetour)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

func GetTourByPrecioBase(db *sql.DB, id int32) (float64, error) {
	row := db.QueryRow(
		"EXEC pa_tour_getPrecioBase @idTour=@p1",
		id,
	)
	var preciobase float64
	err := row.Scan(&preciobase)
	if err != nil {
		return 0, err
	}
	return preciobase, nil
}

func GetToursByTipo(db *sql.DB, tipo string) ([]Tour, error) {
	rows, err := db.Query(
		"EXEC pa_tour_getByTipo @tipo=@p1",
		tipo,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tours []Tour
	for rows.Next() {
		var t Tour
		err := rows.Scan(&t.Idtour, &t.Nombre, &t.Descripcion, &t.Tipo, &t.Disponibilidad, &t.Preciobase, &t.Ubicacion, &t.Imagetour)
		if err != nil {
			return nil, err
		}
		tours = append(tours, t)
	}
	return tours, nil
}

func UpdateTour(db *sql.DB, t Tour) error {
	_, err := db.Exec(
		`EXEC pa_tour_update @idTour=@p1, @nombre=@p2, @descripcion=@p3, @tipo=@p4, 
		 @disponibilidad=@p5, @precioBase=@p6, @ubicacion=@p7, @imageTour=@p8`,
		t.Idtour, t.Nombre, t.Descripcion, t.Tipo, t.Disponibilidad,
		t.Preciobase, t.Ubicacion, t.Imagetour,
	)
	return err
}


