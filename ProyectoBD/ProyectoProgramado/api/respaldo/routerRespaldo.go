package respaldo

import (
	"ProyectoProgramadoI/api/middleware"
	"ProyectoProgramadoI/security"
	"database/sql"

	"github.com/gin-gonic/gin"
)

// RegisterRoutes registra todas las rutas relacionadas con respaldo y restauración
func RegisterRoutes(router *gin.RouterGroup, db *sql.DB, tokenBuilder security.Builder) {
	handler := NewHandler(db, tokenBuilder)

	// Rutas protegidas que requieren autenticación y rol DBA
	respaldoGroup := router.Group("/")
	// Aplicar middleware de autenticación y permisos DBA a todas las rutas
	respaldoGroup.Use(middleware.AuthMiddleware(tokenBuilder), middleware.RequireDBAPermissions())
	{
		// POST /api/v1/respaldo/respaldo - Crear respaldo de la base de datos
		respaldoGroup.POST("/respaldo", handler.CrearRespaldo)
		
		// POST /api/v1/respaldo/restaurar - Restaurar base de datos desde respaldo
		respaldoGroup.POST("/restaurar", handler.RestaurarBaseDatos)
		
		// POST /api/v1/respaldo/respaldos - Listar respaldos disponibles
		respaldoGroup.POST("/respaldos", handler.ListarRespaldos)
		
		// GET /api/v1/respaldo/auditoria - Obtener historial de auditoría DBA
		respaldoGroup.GET("/auditoria", handler.ObtenerAuditoriaDBA)
	}
}