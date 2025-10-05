package dto

import (
	"database/sql"
)

// Funciones CRUD para DetalleReserva usando SQL Server

/*
	func CreateDetalleReserva(db *sql.DB, d Detallereserva) (int32, error) {
		var id int32
		err := db.QueryRow(
			"INSERT INTO detallereserva (reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal) OUTPUT INSERTED.idDetalle VALUES (@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9)",
			d.Reserva, d.Fecha, d.Hora, d.Tour, d.Cantpersonas, d.Factura, d.Precio, d.Descuento, d.Subtotal,
		).Scan(&id)
		if err != nil {
			return 0, err
		}
		return id, nil
	}
*/

func CreateDetalleReserva(db *sql.DB, d Detallereserva) error {
	_, err := db.Exec(
		"EXEC pa_detalleReserva_insert @reserva=@p1, @fecha=@p2, @hora=@p3, @tour=@p4, @cantPersonas=@p5, @precio=@p6, @descuento=@p7, @subTotal=@p8",
		d.Reserva,
		d.Fecha,
		d.Hora,
		d.Tour,
		d.Cantpersonas,
		d.Precio,
		d.Descuento,
		d.Subtotal,
	)
	return err
}

/*
func DeleteDetalleReserva(db *sql.DB, id int32) error {
	_, err := db.Exec("DELETE FROM detallereserva WHERE idDetalle = @p1", id)
	return err
}*/

func DeleteDetalleReserva(db *sql.DB, id int32) error {
	_, err := db.Exec(
		"EXEC pa_detalleReserva_delete @idDetalle=@p1",
		id,
	)
	return err
}

/*
func DeleteDetalleReservaByReserva(db *sql.DB, reserva int32) error {
	_, err := db.Exec("DELETE FROM detallereserva WHERE reserva = @p1", reserva)
	return err
}*/

// SE UTILIZA EN RESERVA.HANDLE.GO
func DeleteDetalleReservaByReserva(db *sql.DB, reserva int32) error {
	_, err := db.Exec(
		"EXEC pa_detallereserva_delete_by_reserva @reserva=@p1",
		reserva,
	)
	return err
}

/*
func GetAllDetalleReservas(db *sql.DB) ([]Detallereserva, error) {
	rows, err := db.Query("SELECT idDetalle, reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal FROM detallereserva")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var detalles []Detallereserva
	for rows.Next() {
		var d Detallereserva
		err := rows.Scan(&d.Iddetalle, &d.Reserva, &d.Fecha, &d.Hora, &d.Tour, &d.Cantpersonas, &d.Factura, &d.Precio, &d.Descuento, &d.Subtotal)
		if err != nil {
			return nil, err
		}
		detalles = append(detalles, d)
	}
	return detalles, nil
}*/

type GetAllDetalleReservasRow struct {
	Iddetalle    int32         `json:"iddetalle"`
	Fecha        string        `json:"fecha"`
	Hora         string        `json:"hora"`
	Cantpersonas int32         `json:"cantpersonas"`
	Nombretour   string        `json:"nombretour"`
	Numreserva   int32         `json:"numreserva"`
	Precio       float64       `json:"precio"`
	Descuento    float64       `json:"descuento"`
	Subtotal     float64       `json:"subtotal"`
}

func GetAllDetalleReservas(db *sql.DB) ([]GetAllDetalleReservasRow, error) {
	rows, err := db.Query("EXEC pa_detalleReserva_getAll")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var detalles []GetAllDetalleReservasRow
	for rows.Next() {
		var d GetAllDetalleReservasRow
		err := rows.Scan(
			&d.Iddetalle,
			&d.Fecha,
			&d.Hora,
			&d.Cantpersonas,
			&d.Nombretour,
			&d.Numreserva,
			&d.Precio,
			&d.Descuento,
			&d.Subtotal,
		)
		if err != nil {
			return nil, err
		}
		detalles = append(detalles, d)
	}
	return detalles, nil
}

/*
func GetDetalleReservaById(db *sql.DB, id int32) (*Detallereserva, error) {
	row := db.QueryRow("SELECT TOP 1 idDetalle, reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal FROM detallereserva WHERE idDetalle = @p1", id)
	var d Detallereserva
	err := row.Scan(&d.Iddetalle, &d.Reserva, &d.Fecha, &d.Hora, &d.Tour, &d.Cantpersonas, &d.Factura, &d.Precio, &d.Descuento, &d.Subtotal)
	if err != nil {
		return nil, err
	}
	return &d, nil
}*/

func GetDetalleReservaById(db *sql.DB, id int32) (*Detallereserva, error) {
	row := db.QueryRow(
		"EXEC pa_detalleReserva_getById @idDetalle=@p1",
		id,
	)

	var d Detallereserva
	err := row.Scan(
		&d.Iddetalle,
		&d.Reserva,
		&d.Fecha,
		&d.Hora,
		&d.Tour,
		&d.Cantpersonas,
		&d.Precio,
		&d.Descuento,
		&d.Subtotal,
	)
	if err != nil {
		return nil, err
	}

	return &d, nil
}

/*
func GetDetalleReservaByReservaId(db *sql.DB, reserva int32) ([]Detallereserva, error) {
	rows, err := db.Query("SELECT idDetalle, reserva, fecha, hora, tour, cantPersonas, factura, precio, descuento, subTotal FROM detallereserva WHERE reserva = @p1", reserva)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var detalles []Detallereserva
	for rows.Next() {
		var d Detallereserva
		err := rows.Scan(&d.Iddetalle, &d.Reserva, &d.Fecha, &d.Hora, &d.Tour, &d.Cantpersonas, &d.Factura, &d.Precio, &d.Descuento, &d.Subtotal)
		if err != nil {
			return nil, err
		}
		detalles = append(detalles, d)
	}
	return detalles, nil
}
*/

func GetDetalleReservaByReservaId(db *sql.DB, reserva int32) ([]Detallereserva, error) {
	rows, err := db.Query(
		"EXEC pa_detalleReserva_getByReserva @reserva=@p1",
		reserva,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var detalles []Detallereserva
	for rows.Next() {
		var d Detallereserva
		err := rows.Scan(
			&d.Iddetalle,
			&d.Reserva,
			&d.Fecha,
			&d.Hora,
			&d.Tour,
			&d.Cantpersonas,
			&d.Precio,
			&d.Descuento,
			&d.Subtotal,
		)
		if err != nil {
			return nil, err
		}
		detalles = append(detalles, d)
	}
	return detalles, nil
}

/*
func GetFacturaByDetalleReservaId(db *sql.DB, id int32) (sql.NullInt32, error) {
	row := db.QueryRow("SELECT factura FROM detallereserva WHERE idDetalle = @p1", id)
	var factura sql.NullInt32
	err := row.Scan(&factura)
	return factura, err
}*/

/*
func UpdateDetalleReserva(db *sql.DB, d Detallereserva) error {
	_, err := db.Exec(
		"UPDATE detallereserva SET reserva=@p1, fecha=@p2, hora=@p3, tour=@p4, cantPersonas=@p5, factura=@p6, precio=@p7, descuento=@p8, subTotal=@p9 WHERE idDetalle=@p10",
		d.Reserva, d.Fecha, d.Hora, d.Tour, d.Cantpersonas, d.Factura, d.Precio, d.Descuento, d.Subtotal, d.Iddetalle,
	)
	return err
}
*/

func UpdateDetalleReserva(db *sql.DB, d Detallereserva) error {
	_, err := db.Exec(
		`EXEC pa_detalleReserva_update 
			@idDetalle=@p1,
			@reserva=@p2,
			@fecha=@p3,
			@hora=@p4,
			@tour=@p5,
			@cantPersonas=@p6,
			@precio=@p7,
			@descuento=@p8,
			@subTotal=@p9`,
		d.Iddetalle,
		d.Reserva,
		d.Fecha,
		d.Hora,
		d.Tour,
		d.Cantpersonas,
		d.Precio,
		d.Descuento,
		d.Subtotal,
	)
	return err
}
