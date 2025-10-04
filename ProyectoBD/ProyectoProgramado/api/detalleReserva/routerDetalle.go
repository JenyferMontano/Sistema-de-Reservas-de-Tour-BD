package detallereserva

import (
	"ProyectoProgramadoI/api/middleware"
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)
	rg.POST("/", middleware.AuthMiddleware(tokenBuilder), h.CreateDetalleReserva)
	rg.GET("/", middleware.AuthMiddleware(tokenBuilder), middleware.RequireRole("admin"), h.GetAllDetallesReserva)
	rg.GET("/:id", middleware.AuthMiddleware(tokenBuilder), h.GetDetalleReservaById)
	rg.PUT("/:id", middleware.AuthMiddleware(tokenBuilder), h.UpdateDetalleReserva)
	rg.GET("/reserva/:reserva", middleware.AuthMiddleware(tokenBuilder), h.GetDetalleReservaByReservaId)
}
