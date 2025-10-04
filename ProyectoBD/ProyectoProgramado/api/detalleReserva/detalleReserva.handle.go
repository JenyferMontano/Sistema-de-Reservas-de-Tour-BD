package detallereserva

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

type createDetalleReservaRequest struct {
	Reserva      int32  `json:"reserva" binding:"required"`
	Fecha        string `json:"fecha" binding:"required"`
	Hora         string `json:"hora" binding:"required"`
	Tour         int32  `json:"tour" binding:"required"`
	CantPersonas int32  `json:"cantPersonas" binding:"required"`
	Factura      *int32 `json:"factura"`
	//Precio       float64 `json:"precio" binding:"required"`
	Descuento float64 `json:"descuento"`
	//SubTotal     float64 `json:"subTotal" binding:"required"`
}

// Crear detalle reserva
func (h *Handler) CreateDetalleReserva(ctx *gin.Context) {
	var req createDetalleReservaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	precioBase, err := dto.GetTourByPrecioBase(h.db, req.Tour)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if req.CantPersonas <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La cantidad de personas debe ser mayor a cero!"})
		return
	}
	if req.Descuento < 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "El descuento no puede ser negativo!"})
		return
	}
	precioTotal := precioBase * float64(req.CantPersonas)
	if req.Descuento > precioTotal {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "El descuento no puede ser mayor que el precio total!!!"})
		return
	}
	subTotal := precioTotal - req.Descuento
	detalle := dto.Detallereserva{
		Reserva:      req.Reserva,
		Fecha:        req.Fecha,
		Hora:         req.Hora,
		Tour:         req.Tour,
		Cantpersonas: req.CantPersonas,
		Factura:      toNullInt32(req.Factura),
		Precio:       precioBase,
		Descuento:    req.Descuento,
		Subtotal:     subTotal,
	}
	err = dto.CreateDetalleReserva(h.db, detalle)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Detalle reserva creado correctamente"})
}

// Obtener por ID Detalle
func (h *Handler) GetDetalleReservaById(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	detalle, err := dto.GetDetalleReservaById(h.db, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"message": "Detalle no encontrado"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, detalle)
}

// Eliminar
func (h *Handler) DeleteDetalleReserva(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	err = dto.DeleteDetalleReserva(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Detalle eliminado correctamente"})
}

// Actualizar
type updateDetalleReservaRequest struct {
	IDDetalle    int32  `json:"idDetalle" binding:"required"`
	Reserva      int32  `json:"reserva" binding:"required"`
	Fecha        string `json:"fecha" binding:"required"`
	Hora         string `json:"hora" binding:"required"`
	Tour         int32  `json:"tour" binding:"required"`
	CantPersonas int32  `json:"cantPersonas" binding:"required"`
	Factura      *int32 `json:"factura"`
	//Precio       float64 `json:"precio" binding:"required"`
	Descuento float64 `json:"descuento"`
	//SubTotal     float64 `json:"subTotal" binding:"required"`
}

func (h *Handler) UpdateDetalleReserva(ctx *gin.Context) {
	var req updateDetalleReservaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	precioBase, err := dto.GetTourByPrecioBase(h.db, req.Tour)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if req.CantPersonas <= 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "La cantidad de personas debe ser mayor a cero!"})
		return
	}
	if req.Descuento < 0 {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "El descuento no puede ser negativo!"})
		return
	}
	precioTotal := precioBase * float64(req.CantPersonas)
	if req.Descuento > precioTotal {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "El descuento no puede ser mayor que el precio total!!!"})
		return
	}
	subTotal := precioTotal - req.Descuento
	detalle := dto.Detallereserva{
		Iddetalle:    req.IDDetalle,
		Reserva:      req.Reserva,
		Fecha:        req.Fecha,
		Hora:         req.Hora,
		Tour:         req.Tour,
		Cantpersonas: req.CantPersonas,
		Factura:      toNullInt32(req.Factura),
		Precio:       precioBase,
		Descuento:    req.Descuento,
		Subtotal:     subTotal,
	}
	err = dto.UpdateDetalleReserva(h.db, detalle)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Detalle actualizado correctamente"})
}

// Obtener todos
func (h *Handler) GetAllDetallesReserva(ctx *gin.Context) {
	detalles, err := dto.GetAllDetalleReservas(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if len(detalles) == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"message": "No hay detalles registrados"})
		return
	}
	ctx.JSON(http.StatusOK, detalles)
}

// Buscar por ID de reserva
func (h *Handler) GetDetalleReservaByReservaId(ctx *gin.Context) {
	reservaStr := ctx.Param("reserva")
	reservaID, err := strconv.Atoi(reservaStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	detalles, err := dto.GetDetalleReservaByReservaId(h.db, int32(reservaID))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if len(detalles) == 0 {
		ctx.JSON(http.StatusNotFound, gin.H{"message": "No hay detalles para esa reserva"})
		return
	}
	ctx.JSON(http.StatusOK, detalles)
}

func toNullInt32(p *int32) sql.NullInt32 {
	if p != nil {
		return sql.NullInt32{Int32: *p, Valid: true}
	}
	return sql.NullInt32{Valid: false}
}

func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
