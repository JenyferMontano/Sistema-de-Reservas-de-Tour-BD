package respaldo

import (
	"ProyectoProgramadoI/dto"
	"ProyectoProgramadoI/security"
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	db           *sql.DB
	tokenBuilder security.Builder
}

func NewHandler(db *sql.DB, tokenBuilder security.Builder) *Handler {
	return &Handler{
		db:           db,
		tokenBuilder: tokenBuilder,
	}
}

// CrearRespaldo maneja la creación de respaldos de la base de datos
func (h *Handler) CrearRespaldo(ctx *gin.Context) {
	var req dto.RespaldoRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de entrada inválidos",
			"details": err.Error(),
		})
		return
	}

	// Obtener información del usuario autenticado
	authorized, exists := ctx.Get("authorized")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario no autenticado",
		})
		return
	}

	payload, ok := authorized.(*security.Payload)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Información del usuario no válida",
		})
		return
	}

	// Verificar que el usuario tenga rol de DBA
	if payload.Rol != "DBA" {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	// Llamar a la función del archivo .sql.go
	resultado, err := dto.CrearRespaldo(h.db, req.RutaRespaldo, payload.Username, req.Descripcion)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al ejecutar respaldo",
			"details": err.Error(),
		})
		return
	}

	// Verificar si el resultado indica error
	if resultado.Resultado == "ERROR" {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": resultado.MensajeError,
			"resultado": resultado.Resultado,
			"usuario_ejecutor": resultado.UsuarioEjecutor,
			"fecha_error": resultado.FechaError,
			"tiempo_ejecucion_ms": resultado.TiempoEjecucionMs,
		})
		return
	}

	// Respuesta exitosa
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": resultado,
	})
}

// RestaurarBaseDatos maneja la restauración de la base de datos
func (h *Handler) RestaurarBaseDatos(ctx *gin.Context) {
	var req dto.RestaurarRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de entrada inválidos",
			"details": err.Error(),
		})
		return
	}

	// Obtener información del usuario autenticado
	authorized, exists := ctx.Get("authorized")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario no autenticado",
		})
		return
	}

	payload, ok := authorized.(*security.Payload)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Información del usuario no válida",
		})
		return
	}

	// Verificar que el usuario tenga rol de DBA
	if payload.Rol != "DBA" {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	// Llamar a la función del archivo .sql.go
	resultado, err := dto.RestaurarBaseDatos(h.db, req.RutaRespaldo, payload.Username, req.Descripcion)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al ejecutar restauración",
			"details": err.Error(),
		})
		return
	}

	// Verificar si el resultado indica error
	if resultado.Resultado == "ERROR" {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": resultado.MensajeError,
			"resultado": resultado.Resultado,
			"usuario_ejecutor": resultado.UsuarioEjecutor,
			"fecha_error": resultado.FechaError,
			"tiempo_ejecucion_ms": resultado.TiempoEjecucionMs,
		})
		return
	}

	// Respuesta exitosa
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": resultado,
	})
}

// ListarRespaldos maneja el listado de respaldos disponibles
func (h *Handler) ListarRespaldos(ctx *gin.Context) {
	var req dto.ListarRespaldosRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de entrada inválidos",
			"details": err.Error(),
		})
		return
	}

	// Obtener información del usuario autenticado
	authorized, exists := ctx.Get("authorized")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario no autenticado",
		})
		return
	}

	payload, ok := authorized.(*security.Payload)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Información del usuario no válida",
		})
		return
	}

	// Verificar que el usuario tenga rol de DBA
	if payload.Rol != "DBA" {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	// Llamar a la función del archivo .sql.go
	respaldos, err := dto.ListarRespaldos(h.db, req.RutaRespaldos)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al listar respaldos",
			"details": err.Error(),
		})
		return
	}

	// Respuesta exitosa
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"respaldos": respaldos,
			"total": len(respaldos),
			"ruta_busqueda": req.RutaRespaldos,
		},
	})
}

// ObtenerAuditoriaDBA obtiene el historial de auditoría DBA
func (h *Handler) ObtenerAuditoriaDBA(ctx *gin.Context) {
	// Obtener información del usuario autenticado
	authorized, exists := ctx.Get("authorized")
	if !exists {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Usuario no autenticado",
		})
		return
	}

	payload, ok := authorized.(*security.Payload)
	if !ok {
		ctx.JSON(http.StatusUnauthorized, gin.H{
			"error": "Información del usuario no válida",
		})
		return
	}

	// Verificar que el usuario tenga rol de DBA
	if payload.Rol != "DBA" {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	// Obtener parámetros de consulta
	limitStr := ctx.DefaultQuery("limit", "50")
	offsetStr := ctx.DefaultQuery("offset", "0")

	// Convertir strings a enteros
	limit := 50
	offset := 0
	if l, err := strconv.Atoi(limitStr); err == nil {
		limit = l
	}
	if o, err := strconv.Atoi(offsetStr); err == nil {
		offset = o
	}

	// Llamar a la función del archivo .sql.go
	auditorias, err := dto.ObtenerAuditoriaDBA(h.db, limit, offset)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al consultar auditoría DBA",
			"details": err.Error(),
		})
		return
	}

	// Respuesta exitosa
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"auditorias": auditorias,
			"total": len(auditorias),
			"limit": limitStr,
			"offset": offsetStr,
		},
	})
}
