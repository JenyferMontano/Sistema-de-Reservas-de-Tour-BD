package persona

import (
	"ProyectoProgramadoI/api/middleware"
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(rg *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	h := NewHandler(db)
	rg.Use(
		middleware.AuthMiddleware(tokenBuilder),
		middleware.RequireRole("admin"),
	)
	rg.POST("/", h.CreatePersona)
	rg.GET("/get/:id", h.GetPersonaById)
	rg.GET("/", h.GetAllPersonas)
	rg.DELETE("/:id", h.DeletePersona)
	rg.PUT("/:id", h.UpdatePersona)
}
