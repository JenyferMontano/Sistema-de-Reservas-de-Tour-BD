package factura

import (
	"ProyectoProgramadoI/api/middleware"
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
	rg.GET("/usuario/:usuario", middleware.AuthMiddleware(tokenBuilder), h.GetFacturasByUsuario)
	rg.GET("/reserva/:reserva", h.GetFacturaByReserva)
	rg.PUT("/estado", h.UpdateFacturaEstado)
	rg.DELETE("/:id", h.DeleteFactura)

}