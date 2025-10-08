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

/*
type createDetalleFacturaRequest struct {
	Factura        int32   `json:"factura" binding:"required"`
	Tour           int32   `json:"tour" binding:"required"`
	CantTour       int32   `json:"cantTour" binding:"required"`
	PrecioTour     float64 `json:"precioTour" binding:"required"`
	Descuento      float64 `json:"descuento"`
	DetalleReserva *int32  `json:"detalleReserva,omitempty"`
}

func (h *Handler) CreateDetalleFactura(ctx *gin.Context) {
	var req createDetalleFacturaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.CantTour <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La cantidad de tours debe ser mayor a cero"})
		return
	}
	if req.Descuento < 0 || req.Descuento > (float64(req.CantTour)*req.PrecioTour) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Descuento inválido"})
		return
	}

	params := dto.CreateDetalleFacturaParams{
		Factura:        req.Factura,
		Tour:           req.Tour,
		CantTour:       req.CantTour,
		PrecioTour:     req.PrecioTour,
		Descuento:      req.Descuento,
		DetalleReserva: req.DetalleReserva,
	}

	idDetalle, err := dto.CreateDetalleFactura(h.db, params)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Detalle factura creado correctamente", "idDetalleFactura": idDetalle})
}

// Actualizar DetalleFactura
type updateDetalleFacturaRequest struct {
	IdDetalleFactura int32   `json:"idDetalleFactura" binding:"required"`
	Tour             int32   `json:"tour" binding:"required"`
	CantTour         int32   `json:"cantTour" binding:"required"`
	PrecioTour       float64 `json:"precioTour" binding:"required"`
	Descuento        float64 `json:"descuento"`
	DetalleReserva   *int32  `json:"detalleReserva,omitempty"`
}

func (h *Handler) UpdateDetalleFactura(ctx *gin.Context) {
	var req updateDetalleFacturaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if req.CantTour <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La cantidad de tours debe ser mayor a cero"})
		return
	}
	if req.Descuento < 0 || req.Descuento > (float64(req.CantTour)*req.PrecioTour) {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Descuento inválido"})
		return
	}

	params := dto.UpdateDetalleFacturaParams{
		IdDetalleFactura: req.IdDetalleFactura,
		Tour:             req.Tour,
		CantTour:         req.CantTour,
		PrecioTour:       req.PrecioTour,
		Descuento:        req.Descuento,
		DetalleReserva:   req.DetalleReserva,
	}

	if err := dto.UpdateDetalleFactura(h.db, params); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Detalle factura actualizado correctamente"})
}
*/


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

/*
// Eliminar un detalle de factura
func (h *Handler) DeleteDetalleFactura(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	err = dto.DeleteDetalleFactura(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al eliminar detalle: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Detalle de factura eliminado correctamente"})
}*/

