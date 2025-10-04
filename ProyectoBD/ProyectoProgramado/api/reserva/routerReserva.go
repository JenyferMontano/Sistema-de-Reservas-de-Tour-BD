package reserva

import (
	"ProyectoProgramadoI/api/middleware"
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)

	// Crear reserva con múltiples detalles
	rg.POST("/crear", h.CreateReservaConDetalles)

	// Operaciones comunes
	rg.GET("/", h.GetAllReservas)
	rg.GET("/:id", h.GetReservaById)
	rg.GET("/huesped/:id", middleware.AuthMiddleware(tokenBuilder), h.GetReservasByHuesped)
	rg.DELETE("/:id", h.DeleteReserva)
	rg.PUT("/estado", h.UpdateEstadoReserva)

}
