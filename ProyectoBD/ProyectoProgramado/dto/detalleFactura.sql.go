package dto

import (
	"database/sql"
	"fmt"
)

type CreateDetalleFacturaParams struct {
	Factura        int32   `json:"factura"`
	Tour           int32   `json:"tour"`
	CantTour       int32   `json:"cantTour"`
	PrecioTour     float64 `json:"precioTour"`
	Descuento      float64 `json:"descuento"`
	DetalleReserva *int32  `json:"detalleReserva,omitempty"`
}

func CreateDetalleFactura(db *sql.DB, p CreateDetalleFacturaParams) (int32, error) {
	var idDetalleFactura int32

	err := db.QueryRow(
		"EXEC pa_detallefactura_insert @factura=@factura, @tour=@tour, @cantTour=@cantTour, @precioTour=@precioTour, @descuento=@descuento, @detalleReserva=@detalleReserva",
		sql.Named("factura", p.Factura),
		sql.Named("tour", p.Tour),
		sql.Named("cantTour", p.CantTour),
		sql.Named("precioTour", p.PrecioTour),
		sql.Named("descuento", p.Descuento),
		sql.Named("detalleReserva", p.DetalleReserva),
	).Scan(&idDetalleFactura)

	if err != nil {
		return 0, fmt.Errorf("error al crear detalle factura: %w", err)
	}

	return idDetalleFactura, nil
}

type UpdateDetalleFacturaParams struct {
	IdDetalleFactura int32   `json:"idDetalleFactura"`
	Tour             int32   `json:"tour"`
	CantTour         int32   `json:"cantTour"`
	PrecioTour       float64 `json:"precioTour"`
	Descuento        float64 `json:"descuento"`
	DetalleReserva   *int32  `json:"detalleReserva,omitempty"`
}

func UpdateDetalleFactura(db *sql.DB, p UpdateDetalleFacturaParams) error {
	_, err := db.Exec(
		"EXEC pa_detallefactura_update @idDetalleFactura=@idDetalleFactura, @tour=@tour, @cantTour=@cantTour, @precioTour=@precioTour, @descuento=@descuento, @detalleReserva=@detalleReserva",
		sql.Named("idDetalleFactura", p.IdDetalleFactura),
		sql.Named("tour", p.Tour),
		sql.Named("cantTour", p.CantTour),
		sql.Named("precioTour", p.PrecioTour),
		sql.Named("descuento", p.Descuento),
		sql.Named("detalleReserva", p.DetalleReserva),
	)

	if err != nil {
		return fmt.Errorf("error al actualizar detalle factura: %w", err)
	}
	return nil
}

type DetalleFacturaAllRows struct {
	IdDetalleFactura int32   `json:"idDetalleFactura"`
	Factura          int32   `json:"factura"`
	NombreTour       string  `json:"nombreTour"`
	CantTour         int32   `json:"cantTour"`
	PrecioTour       float64 `json:"precioTour"`
	Descuento        float64 `json:"descuento"`
	SubTotal         float64 `json:"subTotal"`
	Fecha            *string `json:"fecha,omitempty"`
	Hora             *string `json:"hora,omitempty"`
}

func GetAllDetalleFacturas(db *sql.DB) ([]DetalleFacturaAllRows, error) {
	rows, err := db.Query("EXEC pa_detalleFacturaGetAll")
	if err != nil {
		return nil, fmt.Errorf("error al ejecutar pa_detalleFacturaGetAll: %w", err)
	}
	defer rows.Close()

	var detalles []DetalleFacturaAllRows
	for rows.Next() {
		var d DetalleFacturaAllRows
		var fecha, hora sql.NullString

		err := rows.Scan(&d.IdDetalleFactura, &d.Factura, &d.NombreTour, &d.CantTour, &d.PrecioTour, &d.Descuento, &d.SubTotal, &fecha, &hora)
		if err != nil {
			return nil, fmt.Errorf("error al mapear detalle factura: %w", err)
		}

		if fecha.Valid {
			d.Fecha = &fecha.String
		}
		if hora.Valid {
			d.Hora = &hora.String
		}

		detalles = append(detalles, d)
	}
	return detalles, nil
}

func GetDetalleFacturaById(db *sql.DB, id int32) (Detallefactura, error) {
	var d Detallefactura
	err := db.QueryRow(
		"EXEC pa_detalleFacturaGetById @idDetalleFactura=@idDetalleFactura",
		sql.Named("idDetalleFactura", id),
	).Scan(
		&d.Iddetallefactura,
		&d.Factura,
		&d.Tour,
		&d.Canttour,
		&d.Preciotour,
		&d.Descuento,
		&d.Subtotal,
		&d.DetalleReserva,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return Detallefactura{}, fmt.Errorf("detalle de factura %d no encontrado", id)
		}
		return Detallefactura{}, fmt.Errorf("error al obtener detalle factura: %w", err)
	}
	return d, nil
}

type DetalleFacturaByFacturaRows struct {
	IdDetalleFactura int32   `json:"idDetalleFactura"`
	NombreTour       string  `json:"nombreTour"`
	Ubicacion        string  `json:"ubicacion"`
	CantTour         int32   `json:"cantTour"`
	PrecioTour       float64 `json:"precioTour"`
	Descuento        float64 `json:"descuento"`
	SubTotal         float64 `json:"subTotal"`
}

func GetDetalleFacturaByFactura(db *sql.DB, idFactura int32) ([]DetalleFacturaByFacturaRows, error) {
	rows, err := db.Query("EXEC pa_detallefactura_getbyfactura @idfactura=@idfactura", sql.Named("idfactura", idFactura))
	if err != nil {
		return nil, fmt.Errorf("error al ejecutar pa_detallefactura_getbyfactura: %w", err)
	}
	defer rows.Close()

	var detalles []DetalleFacturaByFacturaRows
	for rows.Next() {
		var d DetalleFacturaByFacturaRows
		err := rows.Scan(&d.IdDetalleFactura, &d.NombreTour, &d.Ubicacion, &d.CantTour, &d.PrecioTour, &d.Descuento, &d.SubTotal)
		if err != nil {
			return nil, fmt.Errorf("error al mapear detalle factura por factura: %w", err)
		}
		detalles = append(detalles, d)
	}
	return detalles, nil
}

func DeleteDetalleFactura(db *sql.DB, idDetalleFactura int32) error {
	_, err := db.Exec("EXEC pa_detallefactura_delete @iddetallefactura=@iddetallefactura",
		sql.Named("iddetallefactura", idDetalleFactura))
	if err != nil {
		return fmt.Errorf("error al eliminar detalle factura: %w", err)
	}
	return nil
}

func DeleteDetalleFacturaByFactura(db *sql.DB, idFactura int32) error {
	_, err := db.Exec("EXEC pa_detallefactura_deleteByFactura @idFactura=@idFactura",
		sql.Named("idFactura", idFactura))
	if err != nil {
		return fmt.Errorf("error al eliminar detalles por factura: %w", err)
	}
	return nil
}

func MigrateDetalleReservaToDetalleFactura(db *sql.DB, idFactura, idReserva int32) error {
	_, err := db.Exec("EXEC pa_migrar_detalleReserva_detalleFactura @idFactura=@idFactura, @idReserva=@idReserva",
		sql.Named("idFactura", idFactura),
		sql.Named("idReserva", idReserva),
	)
	if err != nil {
		return fmt.Errorf("error al migrar detalles de reserva a factura: %w", err)
	}
	return nil
}

