package tour

import (
	"ProyectoProgramadoI/api/middleware"
	"database/sql"

	"ProyectoProgramadoI/security"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)

	// Ruta pública (requiere autenticación pero no solo admin)
	rg.Use(middleware.AuthMiddleware(tokenBuilder))
	rg.GET("/", middleware.RequireRoles("admin", "DBA", "cliente"), h.GetAllTours)

	// Rutas solo para admin y DBA
	adminRoutes := rg.Group("/")
	adminRoutes.Use(middleware.RequireRoles("admin", "DBA"))
	adminRoutes.POST("/", h.CreateTour)
	adminRoutes.GET("/get/:id", h.GetTourById)
	adminRoutes.GET("/tipo/:tipo", h.GetToursByTipo)
	adminRoutes.DELETE("/:id", h.DeleteTour)
	adminRoutes.PUT("/:id", h.UpdateTour)
	adminRoutes.POST("/upload", h.uploadTourImg)
}

func GetTourImgHandler(db *sql.DB) gin.HandlerFunc {
	h := NewHandler(db)
	return h.getTourImg
}
