// en factura/pdf_generator.go

package factura

import (
	"ProyectoProgramadoI/dto" // Asegúrate que la ruta a tu paquete DTO sea correcta
	"fmt"
	"strconv"

	"github.com/jung-kurt/gofpdf"
)

// GenerateInvoicePDF crea un documento PDF para una factura.
// Toma los datos de la factura y sus detalles, y devuelve el objeto PDF listo para ser enviado.
func GenerateInvoicePDF(facturaData *dto.GetFacturaByIdRow, detallesData []dto.DetalleFacturaByFacturaRows) (*gofpdf.Fpdf, error) {
	// --- Configuración Inicial del Documento ---
	pdf := gofpdf.New("P", "mm", "A4", "") // P=Portrait, mm=milímetros, A4
	pdf.AddPage()
	pdf.SetFont("Arial", "", 12)

	// --- Encabezado de la Empresa y Factura ---
	// Logo de la empresa (sección comentada para que la agregues después)
	/*
		// pdf.ImageOptions(
		// 	"./assets/logo.png", // Ruta a tu logo
		// 	10, 10,             // Posición X, Y
		// 	30, 0,              // Ancho (0 para auto-ajustar altura)
		// 	false,              // flow
		// 	gofpdf.ImageOptions{ImageType: "PNG", ReadDpi: true},
		// 	0, "",
		// )
	*/

	// Información de la Empresa (Izquierda)
	pdf.SetXY(10, 15)
	pdf.SetFont("Arial", "B", 14)
	pdf.Cell(40, 10, "Rio Perdido Tours")
	pdf.SetFont("Arial", "", 10)
	pdf.SetXY(10, 22)
	pdf.MultiCell(50, 5, "CRM Reservas Tours y Facturacion\nPailas, Guanacaste, Costa Rica\nTel: +506 8888-8888\nEmail: info@rioperdido.com", "", "L", false)

	// Título de la Factura (Derecha)
	pdf.SetXY(130, 15)
	pdf.SetFont("Arial", "B", 20)
	pdf.Cell(0, 10, "FACTURA")
	pdf.SetFont("Arial", "", 10)
	pdf.SetXY(130, 25)
	pdf.Cell(0, 5, fmt.Sprintf("Factura N°: %06d", facturaData.Idfactura)) // Usa Idfactura con mayúscula
	pdf.SetXY(130, 30)
	pdf.Cell(0, 5, "Fecha: "+facturaData.Fechafactura.Format("02/01/2006")) // Usa Fechafactura con mayúscula

	// --- Información del Cliente ---
	pdf.Line(10, 45, 200, 45) // Línea separadora
	pdf.SetY(50)
	pdf.SetFont("Arial", "B", 12)
	pdf.Cell(40, 10, "Facturar a:")
	pdf.SetFont("Arial", "", 11)
	pdf.SetXY(10, 57)
	// Asegúrate de que los campos en tu struct GetFacturaByIdRow empiecen con mayúscula
	pdf.Cell(0, 6, facturaData.Nombrepersona+" "+facturaData.Apellido1+" "+facturaData.Apellido2)
	// Aquí podrías agregar más datos del cliente si los tuvieras (ej. Cédula, Dirección, etc.)

	// --- Tabla de Detalles de la Factura ---
	pdf.SetY(75)
	// Encabezados de la tabla
	pdf.SetFont("Arial", "B", 10)
	pdf.SetFillColor(220, 220, 220) // Color de fondo gris para el encabezado
	pdf.CellFormat(100, 7, "Descripción", "1", 0, "L", true, 0, "")
	pdf.CellFormat(20, 7, "Cant.", "1", 0, "C", true, 0, "")
	pdf.CellFormat(35, 7, "Precio Unit.", "1", 0, "R", true, 0, "")
	pdf.CellFormat(35, 7, "Subtotal", "1", 1, "R", true, 0, "")

	// Filas de la tabla (los ítems)
	pdf.SetFont("Arial", "", 10)
	pdf.SetFillColor(255, 255, 255)
	for _, item := range detallesData {
		pdf.CellFormat(100, 7, item.NombreTour, "LR", 0, "L", false, 0, "")
		pdf.CellFormat(20, 7, strconv.Itoa(int(item.CantTour)), "LR", 0, "C", false, 0, "")
		pdf.CellFormat(35, 7, fmt.Sprintf("CRC %.2f", item.PrecioTour), "LR", 0, "R", false, 0, "")
		pdf.CellFormat(35, 7, fmt.Sprintf("CRC %.2f", item.SubTotal), "LR", 1, "R", false, 0, "")
	}
	pdf.CellFormat(190, 0, "", "T", 0, "", false, 0, "") // Línea final de la tabla

	// --- Totales de la Factura ---
	totalsY := pdf.GetY() + 5
	pdf.SetFont("Arial", "", 11)
	// Subtotal
	pdf.SetXY(130, totalsY)
	pdf.Cell(35, 7, "Subtotal:")
	pdf.CellFormat(35, 7, fmt.Sprintf("CRC %.2f", facturaData.Subtotal), "", 1, "R", false, 0, "")
	// IVA
	pdf.SetXY(130, totalsY+7)
	pdf.Cell(35, 7, fmt.Sprintf("IVA (%.0f%%):", facturaData.Iva))
	ivaAmount := facturaData.Total - facturaData.Subtotal // Calculamos el monto del IVA
	pdf.CellFormat(35, 7, fmt.Sprintf("CRC %.2f", ivaAmount), "", 1, "R", false, 0, "")
	// Total Final
	pdf.SetFont("Arial", "B", 12)
	pdf.SetXY(130, totalsY+14)
	pdf.Cell(35, 7, "TOTAL:")
	pdf.CellFormat(35, 7, fmt.Sprintf("CRC %.2f", facturaData.Total), "", 1, "R", false, 0, "")

	// --- Pie de Página ---
	pdf.SetY(-30) // Posición a 3 cm del final
	pdf.SetFont("Arial", "I", 8)
	pdf.MultiCell(0, 5, "Esta factura es un comprobante de pago y está sujeta a los términos y condiciones de nuestros servicios. \n¡Gracias por su visita!", "", "C", false)

	return pdf, nil
}