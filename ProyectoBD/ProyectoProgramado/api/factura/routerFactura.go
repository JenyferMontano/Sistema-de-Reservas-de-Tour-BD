package factura

import (
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)
	// POST: Crear una factura (asociada a una reserva y migra detalles)
	rg.POST("/", h.CreateFacturaHandler)

	// GET: Obtener facturas (se recomienda autenticar y limitar a roles de administración)
	rg.GET("/", h.GetAllFacturas)
	rg.GET("/:id", h.GetFacturaById)
	//rg.GET("/usuario/:usuario", h.GetFacturasByUsuario)
	// GET: Obtener facturas por persona
	rg.GET("/persona/:idPersona", h.GetFacturasByPersona)
	rg.GET("/reserva/:reserva", h.GetFacturaByReserva)
	rg.GET("/:id/pdf", h.GetFacturaPDF)
	rg.PUT("/estado", h.UpdateFacturaEstado)
	rg.DELETE("/:id", h.DeleteFactura)

}