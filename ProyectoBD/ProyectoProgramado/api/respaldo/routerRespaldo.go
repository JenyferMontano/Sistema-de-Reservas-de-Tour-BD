package respaldo

import (
	"ProyectoProgramadoI/api/middleware"
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

func RegisterRoutes(router *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	handler := NewHandler(db, tokenBuilder)

	respaldoGroup := router.Group("/")
	respaldoGroup.Use(middleware.AuthMiddleware(tokenBuilder), middleware.RequireDBAPermissions())
	{

		respaldoGroup.POST("/respaldo", handler.CrearRespaldo)

		//respaldoGroup.POST("/restaurar", handler.RestaurarBaseDatos)

		respaldoGroup.POST("/respaldos", handler.ListarRespaldos)

		respaldoGroup.GET("/auditoria", handler.ObtenerAuditoriaDBA)
	}
}