package factura

import (
	"ProyectoProgramadoI/dto"
	"database/sql"
	"net/http"
	"strconv"
	"time"
	"github.com/gin-gonic/gin"
)

type Handler struct {
	db *sql.DB
}

func NewHandler(db *sql.DB) *Handler {
	return &Handler{db: db}
}

type CreateFacturaRequest struct {
	Persona       int32   `json:"persona"`
	Reserva       int32   `json:"reserva"`
	EstadoFactura string  `json:"estadoFactura"`
	MetodoPago    string  `json:"metodoPago"`
	Iva           float64 `json:"iva"`
	Subtotal      float64 `json:"subtotal"`
}

func (h *Handler) CreateFacturaHandler(ctx *gin.Context) {
	var req CreateFacturaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Error al decodificar el JSON: " + err.Error()})
		return
	}

	// Validación básica
	if req.Persona == 0 || req.Reserva == 0 || req.EstadoFactura == "" || req.MetodoPago == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Faltan campos obligatorios"})
		return
	}

	now := time.Now()
	params := dto.CreateFacturaParams{
		Persona:       req.Persona,
		Reserva:       req.Reserva,
		EstadoFactura: req.EstadoFactura,
		FechaFactura:  now,
		MetodoPago:    req.MetodoPago,
		Iva:           req.Iva,
		Subtotal:      req.Subtotal,
		Total:         0, // el total se calcula dentro del PA
	}

	idFactura, err := dto.CreateFactura(h.db, params)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear la factura: " + err.Error()})
		return
	}

	if err := dto.MigrateDetalleReservaToDetalleFactura(h.db, idFactura, req.Reserva); err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al migrar detalles de reserva: " + err.Error()})
		return
	}

    err = dto.UpdateReservaEstado(h.db, req.Reserva, "Facturada")
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"error":   "Factura creada, pero no se pudo actualizar el estado de la reserva",
			"detalle": err.Error(),
		})
		return
	}

	detalles, err := dto.GetDetalleFacturaByFactura(h.db, idFactura)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener detalles migrados: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"mensaje":      "Factura creada y detalles migrados correctamente",
		"idFactura":    idFactura,
		"detalles":     detalles,
		"idReserva":    req.Reserva,
		"idPersona":    req.Persona,
		"estado":       "Facturada",
		"metodoPago":   req.MetodoPago,
		"fechaFactura": now,
	})
}

// Obtener todas las facturas
func (h *Handler) GetAllFacturas(ctx *gin.Context) {
	facturas, err := dto.GetAllFacturas(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, facturas)
}

// Obtener factura por ID
func (h *Handler) GetFacturaById(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}

	factura, err := dto.GetFacturaById(h.db, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"message": "Factura no encontrada"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, factura)
}

// Actualizar estado de factura
func (h *Handler) UpdateFacturaEstado(ctx *gin.Context) {
	var req dto.UpdateFacturaEstadoParams
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err := dto.UpdateFacturaEstado(h.db, req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Estado de la factura actualizado correctamente"})
}

// Eliminar factura
func (h *Handler) DeleteFactura(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

    // Eliminar los detalles primero
	err = dto.DeleteDetalleFacturaByFactura(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al eliminar detalles de factura: " + err.Error()})
		return
	}

	// Luego eliminar la factura
	err = dto.DeleteFactura(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo eliminar la factura: " + err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"message": "Factura eliminada correctamente"})
}

// Obtener facturas por usuario
func (h *Handler) GetFacturasByUsuario(ctx *gin.Context) {
	usuario := ctx.Param("usuario")
	facturas, err := dto.GetFacturasByUsuario(h.db, usuario)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al consultar facturas del usuario"})
		return
	}
	ctx.JSON(http.StatusOK, facturas)
}

// Obtener factura por reserva
func (h *Handler) GetFacturaByReserva(ctx *gin.Context) {
	reservaStr := ctx.Param("reserva")
	reservaID, err := strconv.Atoi(reservaStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID de reserva inválido" + err.Error()})
		return
	}

	factura, err := dto.GetFacturaByReserva(h.db, int32(reservaID))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener factura por reserva: " + err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, factura)
}


func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}