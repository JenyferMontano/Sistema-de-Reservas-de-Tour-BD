// en factura/pdf_generator.go

package factura

import (
	"ProyectoProgramadoI/dto" // Asegúrate que la ruta a tu paquete DTO sea correcta
	"fmt"
	"strconv"
	"strings"

	"github.com/jung-kurt/gofpdf"
)
func utf8ToLatin1(s string) string {
	// Mapeo de caracteres UTF-8 a Latin-1
	replacer := strings.NewReplacer(
		"á", "\xe1", "é", "\xe9", "í", "\xed", "ó", "\xf3", "ú", "\xfa",
		"Á", "\xc1", "É", "\xc9", "Í", "\xcd", "Ó", "\xd3", "Ú", "\xda",
		"ñ", "\xf1", "Ñ", "\xd1",
		"ü", "\xfc", "Ü", "\xdc",
		"°", "\xb0", "º", "\xba",
		"¿", "\xbf", "¡", "\xa1",
		"ç", "\xe7", "Ç", "\xc7",
	)
	return replacer.Replace(s)
}

// GenerateInvoicePDF crea un documento PDF para una factura.
func GenerateInvoicePDF(facturaData *dto.GetFacturaByIdRow, detallesData []dto.DetalleFacturaByFacturaRows) (*gofpdf.Fpdf, error) {
	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.AddPage()

	// --- Encabezado de la Empresa con diseño profesional ---
// --- Encabezado de la Empresa con diseño profesional ---
pdf.SetFillColor(155, 144, 123) // Beige profesional
pdf.Rect(10, 10, 190, 35, "F")

// --- Logo de la empresa ---
logoPath := "C:/Users/jenif/Downloads/I Ciclo 2025/Implementacion de Bases de Datos/Proyecto/ProyectoFinal/ProyectoBases/ProyectoBD/ProyectoProgramado/utils/images/factura_logo/logitoFactura.png"

// Logo más grande (ancho 45 mm, centrado verticalmente)
pdf.ImageOptions(
	logoPath,
	15, 18, // X, Y → un poco más arriba
	48, 0,  // ancho 45 mm, alto proporcional
	false,
	gofpdf.ImageOptions{ImageType: "PNG", ReadDpi: true},
	0,
	"",
)

// --- Información de la empresa ---
pdf.SetTextColor(255, 255, 255)
pdf.SetFont("Arial", "B", 16)
pdf.SetXY(65, 18) // movido a la derecha (antes estaba en 45)
pdf.Cell(0, 8, utf8ToLatin1("Río Perdido Tours"))

pdf.SetFont("Arial", "", 9)
pdf.SetXY(65, 26) // también movido a la derecha
pdf.MultiCell(80, 4, utf8ToLatin1(
	"CRM Reservas Tours y Facturación\nBagaces, Guanacaste, Costa Rica\nTel: +506 2673-3605\nEmail: info@rioperdido.com",
), "", "L", false)

// Restaurar color negro
pdf.SetTextColor(0, 0, 0)


	// --- Sección de Factura (parte superior derecha) ---
	// Fondo blanco para la sección de factura
	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(130, 15, 70, 30, "F")
	
	// Título FACTURA con estilo
	pdf.SetTextColor(155, 144, 123)
	pdf.SetFont("Arial", "B", 24)
	pdf.SetXY(140, 18)
	pdf.Cell(0, 8, "FACTURA")
	
	// Información de la factura
	pdf.SetTextColor(0, 0, 0)
	pdf.SetFont("Arial", "B", 11)
	pdf.SetXY(132, 26)
	pdf.Cell(0, 5, utf8ToLatin1(fmt.Sprintf("Factura N°: %06d", facturaData.Idfactura)))
	pdf.SetXY(132, 31)
	pdf.Cell(0, 5, "Fecha: "+facturaData.Fechafactura.Format("02/01/2006"))
	pdf.SetXY(132, 36)
	pdf.Cell(0, 5, utf8ToLatin1(fmt.Sprintf("Estado: %s", facturaData.Estadofactura)))
	
	// Restaurar color negro
	pdf.SetTextColor(0, 0, 0)

	// --- Información del Cliente con diseño elegante ---
	// Línea separadora con color
	pdf.SetDrawColor(155, 144, 123)
	pdf.SetLineWidth(0.5)
	pdf.Line(10, 52, 200, 52)
	
	// Fondo para la sección del cliente
	pdf.SetFillColor(248, 249, 250) // Gris muy claro
	pdf.Rect(10, 55, 190, 20, "F")
	
	// Título "Facturar a"
	pdf.SetTextColor(155, 144, 123)
	pdf.SetFont("Arial", "B", 12)
	pdf.SetXY(15, 58)
	pdf.Cell(0, 6, utf8ToLatin1("Facturar a:"))

	// Información del cliente
	pdf.SetTextColor(0, 0, 0)
	pdf.SetFont("Arial", "B", 14)
	pdf.SetXY(15, 65)
	pdf.Cell(0, 6, utf8ToLatin1(facturaData.Nombrepersona+" "+facturaData.Apellido1+" "+facturaData.Apellido2))
	
	// Información adicional del cliente
	pdf.SetFont("Arial", "", 10)
	pdf.SetXY(15, 71)
	pdf.Cell(0, 4, utf8ToLatin1(fmt.Sprintf("Identificacion: %d | Reserva: %d", facturaData.Idpersona, facturaData.Numreserva)))
	
	// Restaurar color negro
	pdf.SetTextColor(0, 0, 0)

	// --- Tabla de Detalles de la Factura con estilo profesional ---
	pdf.SetY(85) // Más espacio después del cliente
	
	// Configurar colores y bordes para la tabla
	pdf.SetDrawColor(155, 144, 123) // Bordes azules
	pdf.SetLineWidth(0.3)
	
	// Anchos de columna ajustados sin ubicación (suman 190mm)
	wDesc, wCant, wUnit, wDescVal, wSub := 90.0, 20.0, 30.0, 25.0, 25.0

	// Encabezado de la tabla con estilo
	pdf.SetFillColor(155, 144, 123) // Fondo azul
	pdf.SetTextColor(255, 255, 255) // Texto blanco
	pdf.SetFont("Arial", "B", 10)
	
	pdf.CellFormat(wDesc, 8, utf8ToLatin1("Descripción"), "1", 0, "L", true, 0, "")
	pdf.CellFormat(wCant, 8, "Cant.", "1", 0, "C", true, 0, "")
	pdf.CellFormat(wUnit, 8, "Precio Unit.", "1", 0, "R", true, 0, "")
	pdf.CellFormat(wDescVal, 8, "Descuento", "1", 0, "R", true, 0, "")
	pdf.CellFormat(wSub, 8, "Subtotal", "1", 1, "R", true, 0, "")
	
	// Restaurar colores para las filas de datos
	pdf.SetTextColor(0, 0, 0)
	pdf.SetFillColor(255, 255, 255)

	// Filas de la tabla (los ítems) con alternancia de colores
	pdf.SetFont("Arial", "", 9)
	rowColor := true // Para alternar colores
	for _, item := range detallesData {
		// Alternar color de fondo de las filas
		if rowColor {
			pdf.SetFillColor(248, 249, 250) // Gris muy claro
		} else {
			pdf.SetFillColor(255, 255, 255) // Blanco
		}
		rowColor = !rowColor
		
		// Dibuja las celdas para cada detalle (sin ubicación)
		pdf.CellFormat(wDesc, 8, utf8ToLatin1(item.NombreTour), "LR", 0, "L", true, 0, "")
		pdf.CellFormat(wCant, 8, strconv.Itoa(int(item.CantTour)), "LR", 0, "C", true, 0, "")

		// CORRECCIÓN: Usar USD $
		pdf.CellFormat(wUnit, 8, fmt.Sprintf("USD $%.2f", item.PrecioTour), "LR", 0, "R", true, 0, "")
		pdf.CellFormat(wDescVal, 8, fmt.Sprintf("%.0f%%", item.Descuento), "LR", 0, "R", true, 0, "")
		
		// El SubTotal viene calculado desde la base de datos como: (cantidad × precio) - descuento
		pdf.CellFormat(wSub, 8, fmt.Sprintf("USD $%.2f", item.SubTotal), "LR", 1, "R", true, 0, "")
	}
	pdf.CellFormat(190, 0, "", "T", 0, "", false, 0, "") // Línea final de la tabla

	// --- Totales de la Factura con diseño profesional y alineado ---
	totalsY := pdf.GetY() + 8
	
	// Calcular la posición para alinear con las columnas de Descuento y Subtotal
	// Descuento empieza en: 10 + 90 + 20 + 30 = 150mm
	// Subtotal empieza en: 150 + 25 = 175mm
	// El cuadro debe alinearse con estas columnas
	totalsStartX := 10.0 + 90.0 + 20.0 + 30.0 // 150mm (inicio de Descuento)
	totalsWidth := 25.0 + 25.0 // 50mm (Descuento + Subtotal)
	
	// Fondo para la sección de totales
	pdf.SetFillColor(248, 249, 250)
	pdf.Rect(totalsStartX, totalsY-5, totalsWidth, 40, "F")
	
	// Borde azul
	pdf.SetDrawColor(155, 144, 123)
	pdf.SetLineWidth(1)
	pdf.Rect(totalsStartX, totalsY-5, totalsWidth, 40, "D")
	
	formatCurrency := func(amount float64) string {
		return fmt.Sprintf("USD $%.2f", amount)
	}
	ivaAmount := facturaData.Total - facturaData.Subtotal

	// Subtotal - Label alineado con columna Descuento, valor alineado con columna Subtotal
	pdf.SetFont("Arial", "", 10)
	pdf.SetXY(totalsStartX+2, totalsY)
	pdf.Cell(23, 7, "Subtotal:")
	pdf.SetXY(totalsStartX+27, totalsY)
	pdf.CellFormat(23, 7, formatCurrency(facturaData.Subtotal), "", 0, "R", false, 0, "")

	// IVA - Label alineado con columna Descuento, valor alineado con columna Subtotal
	pdf.SetXY(totalsStartX+2, totalsY+7)
	pdf.Cell(23, 7, fmt.Sprintf("IVA (%.0f%%):", facturaData.Iva))
	pdf.SetXY(totalsStartX+27, totalsY+7)
	pdf.CellFormat(23, 7, formatCurrency(ivaAmount), "", 0, "R", false, 0, "")

	// Línea separadora antes del total
	pdf.SetDrawColor(155, 144, 123)
	pdf.SetLineWidth(0.5)
	pdf.Line(totalsStartX+2, totalsY+14, totalsStartX+totalsWidth-2, totalsY+14)

	// Total Final - Label alineado con columna Descuento, valor alineado con columna Subtotal
	// Fondo azul para destacar el total
	pdf.SetFillColor(155, 144, 123)
	pdf.Rect(totalsStartX+2, totalsY+16, totalsWidth-4, 12, "F")
	
	// Texto blanco para el total con mejor espaciado
	pdf.SetTextColor(255, 255, 255)
	pdf.SetFont("Arial", "B", 10)
	pdf.SetXY(totalsStartX+3, totalsY+19)
	pdf.Cell(22, 6, "TOTAL:")
	pdf.SetXY(totalsStartX+25, totalsY+19)
	pdf.CellFormat(22, 6, formatCurrency(facturaData.Total), "", 0, "R", false, 0, "")
	
	// Restaurar colores
	pdf.SetTextColor(0, 0, 0)
	pdf.SetFillColor(255, 255, 255)

	// --- Pie de Página compacto para una página ---
	pdf.SetAutoPageBreak(false, 0) // evita salto automático por márgenes
	footerY := 285.0               // posición fija segura (A4 = 297mm de alto)
	pdf.SetY(footerY)
	
	// Línea decorativa
	pdf.SetDrawColor(155, 144, 123)
	pdf.SetLineWidth(0.4)
	pdf.Line(10, footerY, 200, footerY)
	
	// Texto centrado justo encima de la línea
	pdf.SetTextColor(78, 72, 62)
	pdf.SetFont("Arial", "", 8)
	pdf.SetY(footerY + 2)
	pdf.CellFormat(0, 4, utf8ToLatin1("Esta factura es un comprobante de pago ¡Gracias por su confianza en Río Perdido!"), "", 0, "C", false, 0, "")
	
	// Restaurar color negro
	pdf.SetTextColor(0, 0, 0)

	return pdf, nil
}