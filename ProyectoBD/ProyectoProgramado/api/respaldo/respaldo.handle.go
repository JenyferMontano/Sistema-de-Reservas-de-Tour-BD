package respaldo

import (
	"ProyectoProgramadoI/dto"
	"ProyectoProgramadoI/security"
	"ProyectoProgramadoI/utils"
	"database/sql"
	"net/http"
	"net/url"
	"strconv"
	"strings"

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

type crearRespaldoRequest struct {
	RutaRespaldo string `json:"ruta_respaldo" binding:"required"`
	Descripcion  string `json:"descripcion"`
}

type restaurarRespaldoRequest struct {
	RutaRespaldo string `json:"ruta_respaldo" binding:"required"`
	Descripcion  string `json:"descripcion"`
}

type listarRespaldosQuery struct {
	RutaRespaldos string `form:"ruta_respaldos" binding:"required"`
}

// CrearRespaldo maneja la creación de respaldos de la base de datos
func (h *Handler) CrearRespaldo(ctx *gin.Context) {
	var req crearRespaldoRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de entrada inválidos",
			"details": err.Error(),
		})
		return
	}

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

	if !strings.EqualFold(payload.Rol, "DBA") {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	resultado, err := dto.CrearRespaldo(h.db, req.RutaRespaldo, payload.Username, req.Descripcion)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al ejecutar respaldo",
			"details": err.Error(),
		})
		return
	}

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

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": resultado,
	})
}

// RestaurarBaseDatos maneja la restauración de la base de datos
func (h *Handler) RestaurarBaseDatos(ctx *gin.Context) {
	var req restaurarRespaldoRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Datos de entrada inválidos",
			"details": err.Error(),
		})
		return
	}

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

	if !strings.EqualFold(payload.Rol, "DBA") {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	masterDB, err := h.openMasterConnection()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "No se pudo iniciar la restauración",
			"details": err.Error(),
		})
		return
	}
	defer masterDB.Close()

	resultado, err := dto.RestaurarBaseDatosConConexionMaster(masterDB, req.RutaRespaldo, payload.Username, req.Descripcion)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al ejecutar restauración",
			"details": err.Error(),
		})
		return
	}

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

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": resultado,
	})
}

// ListarRespaldos maneja el listado de respaldos disponibles
func (h *Handler) ListarRespaldos(ctx *gin.Context) {
	var query listarRespaldosQuery
	if err := ctx.ShouldBindQuery(&query); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Parámetros de entrada inválidos",
			"details": err.Error(),
		})
		return
	}

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

	if !strings.EqualFold(payload.Rol, "DBA") {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	rutaRespaldos := strings.TrimSpace(query.RutaRespaldos)

	if rutaRespaldos == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"error": "Debe indicar la ruta donde se buscarán los respaldos",
		})
		return
	}

	respaldos, err := dto.ListarRespaldos(h.db, rutaRespaldos)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al listar respaldos",
			"details": err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"respaldos": respaldos,
			"total": len(respaldos),
			"ruta_busqueda": rutaRespaldos,
		},
	})
}

// ObtenerAuditoriaDBA obtiene el historial de auditoría DBA
func (h *Handler) ObtenerAuditoriaDBA(ctx *gin.Context) {
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

	if !strings.EqualFold(payload.Rol, "DBA") {
		ctx.JSON(http.StatusForbidden, gin.H{
			"error": "Acceso denegado: Se requieren permisos de DBA",
		})
		return
	}

	limitStr := ctx.DefaultQuery("limit", "50")
	offsetStr := ctx.DefaultQuery("offset", "0")

	limit := 50
	offset := 0
	if l, err := strconv.Atoi(limitStr); err == nil {
		limit = l
	}
	if o, err := strconv.Atoi(offsetStr); err == nil {
		offset = o
	}

	auditorias, err := dto.ObtenerAuditoriaDBA(h.db, limit, offset)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error": "Error al consultar auditoría DBA",
			"details": err.Error(),
		})
		return
	}

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

func (h *Handler) openMasterConnection() (*sql.DB, error) {
	config, err := utils.LoadConfig(".")
	if err != nil {
		return nil, err
	}

	masterURL, err := url.Parse(config.DBSource)
	if err != nil {
		return nil, err
	}

	query := masterURL.Query()
	query.Set("database", "master")
	masterURL.RawQuery = query.Encode()

	masterDB, err := sql.Open(config.DBDriver, masterURL.String())
	if err != nil {
		return nil, err
	}

	return masterDB, nil
}
