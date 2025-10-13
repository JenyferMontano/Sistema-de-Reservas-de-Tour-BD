package dto

import (
	"database/sql"
	"fmt"
	"time"
)

// Funciones CRUD para Reserva usando SQL Server

type CreateReservaParams struct {
	Usuario       string    `json:"usuario"`
	Huesped       int32     `json:"huesped"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
	Subtotal      float64   `json:"subtotal"`
	Impuesto      float64   `json:"impuesto"`
	Total         float64   `json:"total"`
}

func CreateReserva(db *sql.DB, r CreateReservaParams) (int32, error) {
	fechaStr := r.Fechareserva.Format("02/01/2006 15:04")

	_, err := db.Exec(
		"EXEC pa_reserva_insert @usuario=@usuario, @huesped=@huesped, @estadoReserva=@estado, @fechaReservaStr=@fecha, @subTotal=@subtotal, @impuesto=@impuesto, @total=@total",
		sql.Named("usuario", r.Usuario),
		sql.Named("huesped", r.Huesped),
		sql.Named("estado", r.Estadoreserva),
		sql.Named("fecha", fechaStr),
		sql.Named("subtotal", r.Subtotal),
		sql.Named("impuesto", r.Impuesto),
		sql.Named("total", r.Total),
	)
	if err != nil {
		return 0, err
	}

	var id int32
	err = db.QueryRow(
		"SELECT TOP 1 numReserva FROM reserva WHERE usuario=@usuario AND huesped=@huesped ORDER BY numReserva DESC",
		sql.Named("usuario", r.Usuario),
		sql.Named("huesped", r.Huesped),
	).Scan(&id)
	if err != nil {
		return 0, err
	}

	return id, nil
}

func DeleteReserva(db *sql.DB, id int32) error {
	_, err := db.Exec(
		"EXEC pa_reserva_delete @numReserva=@id",
		sql.Named("id", id),
	)
	if err != nil {
		return fmt.Errorf("no se pudo eliminar la reserva: %w", err)
	}
	return nil
}

type GetAllReservasRow struct {
	Numreserva    int32     `json:"numreserva"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
	Subtotal      float64   `json:"subtotal"`
	Impuesto      float64   `json:"impuesto"`
	Total         float64   `json:"total"`
	Nombreusuario string    `json:"nombreusuario"`
	IdPersona     int32     `json:"idpersona"`
	Nombrecliente string    `json:"nombrecliente"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
}

func GetAllReservas(db *sql.DB) ([]GetAllReservasRow, error) {
	rows, err := db.Query("EXEC pa_reserva_getall")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reservas []GetAllReservasRow
	for rows.Next() {
		var r GetAllReservasRow
		err := rows.Scan(
			&r.Numreserva,
			&r.Estadoreserva,
			&r.Fechareserva,
			&r.Subtotal,
			&r.Impuesto,
			&r.Total,
			&r.Nombreusuario,
			&r.IdPersona,
			&r.Nombrecliente,
			&r.Apellido1,
			&r.Apellido2,
		)
		if err != nil {
			return nil, err
		}
		reservas = append(reservas, r)
	}

	return reservas, nil
}

type GetReservaByIdRow struct {
	Numreserva    int32     `json:"numreserva"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
	Subtotal      float64   `json:"subtotal"`
	Impuesto      float64   `json:"impuesto"`
	Total         float64   `json:"total"`
	Nombreusuario string    `json:"nombreusuario"`
	Nombrecliente string    `json:"nombrecliente"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
}

func GetReservaById(db *sql.DB, id int32) (*GetReservaByIdRow, error) {
	// Usamos sql.Named para pasar parámetros a SQL Server
	row := db.QueryRow("EXEC pa_reserva_getbyid @numReserva=@id", sql.Named("id", id))

	var r GetReservaByIdRow
	err := row.Scan(
		&r.Numreserva,
		&r.Estadoreserva,
		&r.Fechareserva,
		&r.Subtotal,
		&r.Impuesto,
		&r.Total,
		&r.Nombreusuario,
		&r.Nombrecliente,
		&r.Apellido1,
		&r.Apellido2,
	)
	if err != nil {
		return nil, err
	}

	return &r, nil
}

type GetReservasByUsuarioRow struct {
	Numreserva    int32     `json:"numreserva"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
	Subtotal      float64   `json:"subtotal"`
	Impuesto      float64   `json:"impuesto"`
	Total         float64   `json:"total"`
	Usuario       string    `json:"usuario"`
}

func GetReservasByUsuario(db *sql.DB, usuario string) ([]GetReservasByUsuarioRow, error) {
	rows, err := db.Query(
		"EXEC pa_reservas_by_usuario @usuario=@u",
		sql.Named("u", usuario),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reservas []GetReservasByUsuarioRow
	for rows.Next() {
		var r GetReservasByUsuarioRow
		err := rows.Scan(
			&r.Numreserva,
			&r.Estadoreserva,
			&r.Fechareserva,
			&r.Subtotal,
			&r.Impuesto,
			&r.Total,
			&r.Usuario,
		)
		if err != nil {
			return nil, err
		}
		reservas = append(reservas, r)
	}

	return reservas, nil
}

type GetReservasByPersonaRow struct {
	Numreserva    int32     `json:"numreserva"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
	Subtotal      float64   `json:"subtotal"`
	Impuesto      float64   `json:"impuesto"`
	Total         float64   `json:"total"`
	Nombreusuario string    `json:"nombreusuario"`
	Nombrecliente string    `json:"nombrecliente"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
}

func GetReservasByPersona(db *sql.DB, huesped int32) ([]GetReservasByPersonaRow, error) {
	query := "EXEC dbo.pa_reservas_by_persona @idPersona=@p"
	rows, err := db.Query(query, sql.Named("p", huesped))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reservas []GetReservasByPersonaRow
	for rows.Next() {
		var r GetReservasByPersonaRow
		err := rows.Scan(
			&r.Numreserva,
			&r.Estadoreserva,
			&r.Fechareserva,
			&r.Subtotal,
			&r.Impuesto,
			&r.Total,
			&r.Nombreusuario,
			&r.Nombrecliente,
			&r.Apellido1,
			&r.Apellido2,
		)
		if err != nil {
			return nil, err
		}
		reservas = append(reservas, r)
	}

	return reservas, nil
}

type UpdateReservaParams struct {
	Numreserva    int32     `json:"numreserva"`
	Usuario       string    `json:"usuario"`
	Huesped       int32     `json:"huesped"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
	Subtotal      float64   `json:"subtotal"`
	Impuesto      float64   `json:"impuesto"`
	Total         float64   `json:"total"`
}

func UpdateReserva(db *sql.DB, r UpdateReservaParams) error {
	fechaStr := r.Fechareserva.Format("2006-01-02 15:04:05")

	_, err := db.Exec(
		"EXEC pa_reserva_update @numReserva=@id, @usuario=@usuario, @huesped=@huesped, @estadoReserva=@estado, @fechaReservaStr=@fecha, @subTotal=@subtotal, @impuesto=@impuesto, @total=@total",
		sql.Named("id", r.Numreserva),
		sql.Named("usuario", r.Usuario),
		sql.Named("huesped", r.Huesped),
		sql.Named("estado", r.Estadoreserva),
		sql.Named("fecha", fechaStr),
		sql.Named("subtotal", r.Subtotal),
		sql.Named("impuesto", r.Impuesto),
		sql.Named("total", r.Total),
	)
	return err
}

type UpdateReservaEstadoParams struct {
	Numreserva    int32  `json:"numreserva"`
	Estadoreserva string `json:"estadoreserva"`
}

func UpdateReservaEstado(db *sql.DB, numReserva int32, estado string) error {
	_, err := db.Exec(
		"EXEC pa_reserva_update_estado @numReserva=@id, @estadoReserva=@estado",
		sql.Named("id", numReserva),
		sql.Named("estado", estado),
	)
	return err
}
