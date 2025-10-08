package detallefactura

import (
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)

	// GET: Obtener todos los detalles de factura
	rg.GET("/", h.GetAllDetalleFacturas)

	// GET: Obtener los detalles por ID de factura
	rg.GET("/factura/:idFactura", h.GetDetalleFacturaByFactura)

	// GET: Obtener un detalle específico por su ID
	rg.GET("/:id", h.GetDetalleFacturaById)

	// POST: Crear un nuevo detalle de factura (generalmente no se usa porque se migra desde la reserva)
	//rg.POST("/", middleware.AuthMiddleware(tokenBuilder), h.CreateDetalleFactura)

	// PUT: Actualizar un detalle de factura
	//rg.PUT("/:idDetalle", middleware.AuthMiddleware(tokenBuilder), h.UpdateDetalleFactura)

	// DELETE: Eliminar un detalle de factura
	//rg.DELETE("/:idDetalle", middleware.AuthMiddleware(tokenBuilder), h.DeleteDetalleFactura)
}
