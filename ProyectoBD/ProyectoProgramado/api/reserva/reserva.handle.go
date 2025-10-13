package reserva

import (
	"ProyectoProgramadoI/dto"
	"database/sql"
	"fmt"
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

// Estructura para un detalle recibido desde frontend
type DetalleInput struct {
	Fecha        string  `json:"fecha" binding:"required"`
	Hora         string  `json:"hora" binding:"required"`
	Tour         int32   `json:"tour" binding:"required"`
	CantPersonas int32   `json:"cantPersonas" binding:"required"`
	Descuento    float64 `json:"descuento"`
}

// Estructura general del request
type CreateReservaRequest struct {
	Usuario  string         `json:"usuario" binding:"required"`
	Huesped  int32          `json:"huesped" binding:"required"`
	Estado   string         `json:"estadoReserva" binding:"required"`
	Fecha    string         `json:"fechaReserva" binding:"required"`
	Detalles []DetalleInput `json:"detalles" binding:"required,min=1"`
}

// Crear reserva con múltiples detalles
func (h *Handler) CreateReservaConDetalles(ctx *gin.Context) {
	var req CreateReservaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Datos inválidos", "detalle": err.Error()})
		return
	}
	fechaReserva, err := time.Parse("02/01/2006 15:04", req.Fecha)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Formato de fechaReserva inválido"})
		return
	}
	var subTotal float64 = 0
	var detallesFinales []dto.Detallereserva
	for _, d := range req.Detalles {
		if d.CantPersonas <= 0 {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Cantidad de personas debe ser mayor que cero"})
			return
		}
		if d.Descuento < 0 {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "Descuento no puede ser negativo"})
			return
		}
		precioBase, err := dto.GetTourByPrecioBase(h.db, d.Tour)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al obtener precio base del tour"})
			return
		}
		precio := precioBase
		precioTotal := precioBase * float64(d.CantPersonas)
		if d.Descuento > precioTotal {
			ctx.JSON(http.StatusBadRequest, gin.H{"error": "El descuento no puede ser mayor al precio total"})
			return
		}
		subTotalDetalle := precioTotal - d.Descuento
		subTotal += subTotalDetalle
		detallesFinales = append(detallesFinales, dto.Detallereserva{
			Fecha:        d.Fecha,
			Hora:         d.Hora,
			Tour:         d.Tour,
			Cantpersonas: d.CantPersonas,
			Precio:       precio,
			Descuento:    d.Descuento,
			Subtotal:     subTotalDetalle,
		})
	}
	impuesto := subTotal * 0.13
	total := subTotal + impuesto
	argsReserva := dto.CreateReservaParams{
		Usuario:       req.Usuario,
		Huesped:       req.Huesped,
		Estadoreserva: req.Estado,
		Fechareserva:  fechaReserva,
		Subtotal:      subTotal,
		Impuesto:      impuesto,
		Total:         total,
	}
	idReserva, err := dto.CreateReserva(h.db, argsReserva)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear la reserva"})
		return
	}
	for _, d := range detallesFinales {
		d.Reserva = idReserva
		fmt.Printf("Intentando guardar detalle: %+v\n", d)
		err := dto.CreateDetalleReserva(h.db, d)
		if err != nil {
			fmt.Println("Error SQL:", err)
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al guardar detalles de reserva"})
			return
		}
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Reserva creada correctamente", "numReserva": idReserva})
}

func (h *Handler) GetAllReservas(ctx *gin.Context) {
	reservas, err := dto.GetAllReservas(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, reservas)
}

func (h *Handler) GetReservaById(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	reserva, err := dto.GetReservaById(h.db, int32(id))
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"message": "Reserva no encontrada"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, reserva)
}

// Buscar reserva por huesped
func (h *Handler) GetReservasByHuesped(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "ID inválido"})
		return
	}
	reservas, err := dto.GetReservasByPersona(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al consultar reservas"})
		return
	}
	ctx.JSON(http.StatusOK, reservas)
}

func (h *Handler) GetReservasByUsuario(ctx *gin.Context) {
	usuario := ctx.Param("usuario")
	if usuario == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Usuario no proporcionado"})
		return
	}

	reservas, err := dto.GetReservasByUsuario(h.db, usuario)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al consultar reservas"})
		return
	}

	ctx.JSON(http.StatusOK, reservas)
}


func (h *Handler) DeleteReserva(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	// Eliminar los detalles primero
	err = dto.DeleteDetalleReservaByReserva(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al eliminar detalles de reserva: " + err.Error()})
		return
	}
	// Luego eliminar la reserva
	err = dto.DeleteReserva(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al eliminar reserva: " + err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Reserva eliminada correctamente"})
}

// Cambiar estado de la reserva
type UpdateEstadoReservaRequest struct {
	NumReserva    int32  `json:"numReserva" binding:"required"`
	EstadoReserva string `json:"estadoReserva" binding:"required"`
}

func (h *Handler) UpdateEstadoReserva(ctx *gin.Context) {
	var req UpdateEstadoReservaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	err := dto.UpdateReservaEstado(h.db, req.NumReserva, req.EstadoReserva)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Estado actualizado correctamente"})
}

func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
