package detallefactura

import (
	"ProyectoProgramadoI/dto"
	"database/sql"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	db *sql.DB
}

func NewHandler(db *sql.DB) *Handler {
	return &Handler{db: db}
}
// Obtener todos los detalles de factura
func (h *Handler) GetAllDetalleFacturas(ctx *gin.Context) {
	detalles, err := dto.GetAllDetalleFacturas(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, detalles)
}

// Obtener detalle de factura por ID
func (h *Handler) GetDetalleFacturaById(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	detalle, err := dto.GetDetalleFacturaById(h.db, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"message": "Detalle de factura no encontrado"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, detalle)
}

// Obtener detalles por factura
func (h *Handler) GetDetalleFacturaByFactura(ctx *gin.Context) {
	idStr := ctx.Param("idFactura")
	idFactura, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID de factura inválido"})
		return
	}

	detalles, err := dto.GetDetalleFacturaByFactura(h.db, int32(idFactura))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, detalles)
}


