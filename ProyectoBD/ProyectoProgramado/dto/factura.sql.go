package dto

import (
	"database/sql"
	"fmt"
	"time"
)

// Funciones CRUD para Factura usando SQL Server
type CreateFacturaParams struct {
	Persona       int32     `json:"persona"`
	Reserva       int32     `json:"reserva"`
	EstadoFactura string    `json:"estadoFactura"`
	FechaFactura  time.Time `json:"fechaFactura"`
	MetodoPago    string    `json:"metodoPago"`
	Iva           float64   `json:"iva"`
	Subtotal      float64   `json:"subtotal"`
	Total         float64   `json:"total"`
}

func CreateFactura(db *sql.DB, f CreateFacturaParams) (int32, error) {
	var idFactura int32
	fechaStr := f.FechaFactura.Format("02/01/2006")
	err := db.QueryRow(
		"EXEC pa_factura_insert @persona=@persona, @reserva=@reserva, @estadoFactura=@estadoFactura, @fechaFacturaStr=@fechaFacturaStr, @metodoPago=@metodoPago, @iva=@iva, @subtotal=@subtotal",
		sql.Named("persona", f.Persona),
		sql.Named("reserva", f.Reserva),
		sql.Named("estadoFactura", f.EstadoFactura),
		sql.Named("fechaFacturaStr", fechaStr),
		sql.Named("metodoPago", f.MetodoPago),
		sql.Named("iva", f.Iva),
		sql.Named("subtotal", f.Subtotal),
	).Scan(&idFactura)

	if err != nil {
		return 0, err
	}

	return idFactura, nil
}

type UpdateFacturaEstadoParams struct {
	IDFactura     int32  `json:"idFactura"`
	EstadoFactura string `json:"estadoFactura"`
}

func UpdateFacturaEstado(db *sql.DB, f UpdateFacturaEstadoParams) error {
	_, err := db.Exec(
		"EXEC pa_factura_update_estado @idFactura=@idFactura, @estadoFactura=@estadoFactura",
		sql.Named("idFactura", f.IDFactura),
		sql.Named("estadoFactura", f.EstadoFactura),
	)
	return err
}

func DeleteFactura(db *sql.DB, idFactura int32) error {
	_, err := db.Exec(
		"EXEC pa_factura_delete @idFactura=@idFactura",
		sql.Named("idFactura", idFactura),
	)
	if err != nil {
		return fmt.Errorf("no se pudo eliminar la factura: %w", err)
	}
	return nil
}

type FacturaBaseRows struct {
	IDFactura     int32     `json:"idFactura"`
	Persona       int32     `json:"persona"`
	Reserva       int32     `json:"reserva"`
	EstadoFactura string    `json:"estadoFactura"`
	FechaFactura  time.Time `json:"fechaFactura"`
	MetodoPago    string    `json:"metodoPago"`
	Iva           float64   `json:"iva"`
	Subtotal      float64   `json:"subtotal"`
	Total         float64   `json:"total"`
	Nombrepersona string    `json:"nombrepersona"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
	Estadoreserva string    `json:"estadoreserva"`
}

func GetFacturaByReserva(db *sql.DB, numReserva int32) (FacturaBaseRows, error) {
	var f FacturaBaseRows
	var fecha time.Time

	query := "EXEC pa_facturaGetByReserva @reserva"
	row := db.QueryRow(query, sql.Named("reserva", numReserva))

	err := row.Scan(
		&f.IDFactura, &f.Persona, &f.Reserva, &f.EstadoFactura, &fecha, &f.MetodoPago,
		&f.Iva, &f.Subtotal, &f.Total, &f.Nombrepersona,
		&f.Apellido1,
		&f.Apellido2,
		&f.Estadoreserva,
	)

	f.FechaFactura = fecha
	if err != nil {
		if err == sql.ErrNoRows {
			return FacturaBaseRows{}, fmt.Errorf("no se encontró factura para la reserva %d: %w", numReserva, err)
		}
		return FacturaBaseRows{}, fmt.Errorf("error al ejecutar pa_facturaGetByReserva: %w", err)
	}

	return f, nil
}

type FacturaUsuarioRows struct {
	IDFactura     int32     `json:"idFactura"`
	EstadoFactura string    `json:"estadoFactura"`
	FechaFactura  time.Time `json:"fechaFactura"`
	MetodoPago    string    `json:"metodoPago"`
	Iva           float64   `json:"iva"`
	Subtotal      float64   `json:"subtotal"`
	Total         float64   `json:"total"`
	Idpersona     int32     `json:"idpersona"`
	Nombrepersona string    `json:"nombrepersona"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
	NumReserva    int32     `json:"numReserva"`
	EstadoReserva string    `json:"estadoReserva"`
}

func GetFacturasByUsuario(db *sql.DB, usuario string) ([]FacturaUsuarioRows, error) {
	query := "EXEC pa_facturasGetByUsuario @usuario"
	rows, err := db.Query(query, sql.Named("usuario", usuario))
	if err != nil {
		return nil, fmt.Errorf("error al consultar facturas por usuario: %w", err)
	}
	defer rows.Close()

	facturas := []FacturaUsuarioRows{}

	for rows.Next() {
		var f FacturaUsuarioRows
		err := rows.Scan(
			&f.IDFactura,
			&f.EstadoFactura,
			&f.FechaFactura,
			&f.MetodoPago,
			&f.Iva,
			&f.Subtotal,
			&f.Total,
			&f.Idpersona,
			&f.Nombrepersona,
			&f.Apellido1,
			&f.Apellido2,
			&f.NumReserva,
			&f.EstadoReserva,
		)
		if err != nil {
			return nil, fmt.Errorf("error al mapear resultado de factura por usuario: %w", err)
		}
		facturas = append(facturas, f)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error al iterar sobre resultados de factura por usuario: %w", err)
	}

	return facturas, nil
}

type FacturaPersonaRows struct {
	IDFactura     int32     `json:"idFactura"`
	EstadoFactura string    `json:"estadoFactura"`
	FechaFactura  time.Time `json:"fechaFactura"`
	MetodoPago    string    `json:"metodoPago"`
	Iva           float64   `json:"iva"`
	Subtotal      float64   `json:"subtotal"`
	Total         float64   `json:"total"`
	Idpersona     int32     `json:"idpersona"`
	Nombrepersona string    `json:"nombrepersona"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
	NumReserva    int32     `json:"numReserva"`
	EstadoReserva string    `json:"estadoReserva"`
	FechaReserva  time.Time `json:"fechareserva"`
}

func GetFacturasByPersona(db *sql.DB, idPersona int32) ([]FacturaPersonaRows, error) {
	query := "EXEC pa_facturasGetByPersona @idPersona"
	rows, err := db.Query(query, sql.Named("idPersona", idPersona))
	if err != nil {
		return nil, fmt.Errorf("error al consultar facturas por persona: %w", err)
	}
	defer rows.Close()

	var facturas []FacturaPersonaRows

	for rows.Next() {
		var f FacturaPersonaRows
		err := rows.Scan(
			&f.IDFactura,
			&f.EstadoFactura,
			&f.FechaFactura,
			&f.MetodoPago,
			&f.Iva,
			&f.Subtotal,
			&f.Total,
			&f.Idpersona,
			&f.Nombrepersona,
			&f.Apellido1,
			&f.Apellido2,
			&f.NumReserva,
			&f.EstadoReserva,
			&f.FechaReserva,
		)
		if err != nil {
			return nil, fmt.Errorf("error al mapear resultado de factura por persona: %w", err)
		}
		facturas = append(facturas, f)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error al iterar sobre resultados de factura por persona: %w", err)
	}

	return facturas, nil
}


type GetAllFacturasRow struct {
	Idfactura     int32     `json:"idfactura"`
	Estadofactura string    `json:"estadofactura"`
	Fechafactura  time.Time `json:"fechafactura"`
	Metodopago    string    `json:"metodopago"`
	Iva           float64   `json:"iva"`
	Subtotal      float64   `json:"subtotal"`
	Total         float64   `json:"total"`
	Idpersona     int32     `json:"idpersona"`
	Nombrepersona string    `json:"nombrepersona"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
	Usuario       string    `json:"usuario"`
	Numreserva    int32     `json:"numreserva"`
	Estadoreserva string    `json:"estadoreserva"`
}

func GetAllFacturas(db *sql.DB) ([]GetAllFacturasRow, error) {
	rows, err := db.Query("SELECT * FROM vw_facturasGetAll")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var facturas []GetAllFacturasRow
	for rows.Next() {
		var f GetAllFacturasRow
		err := rows.Scan(
			&f.Idfactura,
			&f.Estadofactura,
			&f.Fechafactura,
			&f.Metodopago,
			&f.Iva,
			&f.Subtotal,
			&f.Total,
			&f.Idpersona,
			&f.Nombrepersona,
			&f.Apellido1,
			&f.Apellido2,
			&f.Usuario,
			&f.Numreserva,
			&f.Estadoreserva,
		)
		if err != nil {
			return nil, err
		}
		facturas = append(facturas, f)
	}

	return facturas, nil
}

type GetFacturaByIdRow struct {
	Idfactura     int32     `json:"idfactura"`
	Estadofactura string    `json:"estadofactura"`
	Fechafactura  time.Time `json:"fechafactura"`
	Metodopago    string    `json:"metodopago"`
	Iva           float64   `json:"iva"`
	Subtotal      float64   `json:"subtotal"`
	Total         float64   `json:"total"`
	Idpersona     int32     `json:"idpersona"`
	Nombrepersona string    `json:"nombrepersona"`
	Apellido1     string    `json:"apellido_1"`
	Apellido2     string    `json:"apellido_2"`
	Numreserva    int32     `json:"numreserva"`
	Estadoreserva string    `json:"estadoreserva"`
	Fechareserva  time.Time `json:"fechareserva"`
}

func GetFacturaById(db *sql.DB, id int32) (*GetFacturaByIdRow, error) {
	row := db.QueryRow("EXEC pa_facturaGetById @idFactura=@id", sql.Named("id", id))

	var f GetFacturaByIdRow
	err := row.Scan(
		&f.Idfactura,
		&f.Estadofactura,
		&f.Fechafactura,
		&f.Metodopago,
		&f.Iva,
		&f.Subtotal,
		&f.Total,
		&f.Idpersona,
		&f.Nombrepersona,
		&f.Apellido1,
		&f.Apellido2,
		&f.Numreserva,
		&f.Estadoreserva,
		&f.Fechareserva,
	)
	if err != nil {
		return nil, err
	}

	return &f, nil
}
