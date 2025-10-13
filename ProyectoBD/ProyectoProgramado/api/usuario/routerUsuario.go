package usuario

import (
	"ProyectoProgramadoI/api/middleware"
	"ProyectoProgramadoI/security"
	"database/sql"
	"time"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, builder security.Builder, tokenDuration time.Duration) {
	h := NewHandler(db, builder, tokenDuration)
	adminGroup := rg.Group("/")
	adminGroup.Use(
		middleware.AuthMiddleware(builder),
		middleware.RequireRole("admin"),
	)
	adminGroup.POST("/", h.CreateUsuario)
	adminGroup.GET("/", h.GetAllUsuarios)
	//adminGroup.GET("/:username", h.GetUsuarioByUsername)
	adminGroup.DELETE("/:username", h.DeleteUsuario)

	rg.PUT("/:username", middleware.AuthMiddleware(builder), h.UpdateUsuario)
	rg.GET("/:username", middleware.AuthMiddleware(builder), h.GetUsuarioByUsername)
	rg.POST("/upload", middleware.AuthMiddleware(builder), h.uploadUsuarioImg)
	rg.GET("/images/:name", h.getUsuarioImg) //publico
}
