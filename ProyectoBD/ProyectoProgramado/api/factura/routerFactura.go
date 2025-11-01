package factura

import (
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)

	rg.POST("/", h.CreateFacturaHandler)
	rg.GET("/", h.GetAllFacturas)
	rg.GET("/:id", h.GetFacturaById)
	rg.GET("/persona/:idPersona", h.GetFacturasByPersona)
	rg.GET("/reserva/:reserva", h.GetFacturaByReserva)
	rg.GET("/:id/pdf", h.GetFacturaPDF)
	rg.PUT("/estado", h.UpdateFacturaEstado)
	rg.DELETE("/:id", h.DeleteFactura)

}