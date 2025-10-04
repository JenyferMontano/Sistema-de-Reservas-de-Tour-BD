package persona

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

type createPersonaRequest struct {
	Idpersona int32     `json:"id_persona" binding:"required"`
	Nombre    string    `json:"nombre" binding:"required"`
	Apellido1 string    `json:"apellido_1" binding:"required"`
	Apellido2 string    `json:"apellido_2" binding:"required"`
	FechaNac  time.Time `json:"fecha_nac" binding:"required"`
	Direccion string    `json:"direccion" binding:"required"`
	Telefono  string    `json:"telefono" binding:"required"`
	Correo    string    `json:"correo" binding:"required,email"`
}

func (h *Handler) CreatePersona(ctx *gin.Context) {
    var req createPersonaRequest
    if err := ctx.ShouldBindJSON(&req); err != nil {
        ctx.JSON(http.StatusBadRequest, errorResponse(err))
        return
    }

    p := dto.Persona{
        IdPersona: req.Idpersona,
        Nombre:    req.Nombre,
        Apellido1: req.Apellido1,
        Apellido2: req.Apellido2,
        FechaNac:  req.FechaNac,
        Direccion: req.Direccion,
        Telefono:  req.Telefono,
        Correo:    req.Correo,
    }

    err := dto.CreatePersona(h.db, p)
    if err != nil {
        ctx.JSON(http.StatusInternalServerError, errorResponse(err))
        return
    }

    ctx.JSON(http.StatusOK, gin.H{
        "message":    "Persona creada correctamente",
        "idPersona":  p.IdPersona,
        "nombre":     p.Nombre,
        "apellido_1": p.Apellido1,
        "apellido_2": p.Apellido2,
        "fecha_nac":  p.FechaNac.Format("02/01/2006"),
        "direccion":  p.Direccion,
        "telefono":   p.Telefono,
        "correo":     p.Correo,
    })
}


// Obtener persona por id
type getPersonaByIdRequest struct {
	Idpersona int32 `uri:"id" binding:"required,min=1"`
}

func (h *Handler) GetPersonaById(ctx *gin.Context) {
	var req getPersonaByIdRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	persona, err := dto.GetPersonaById(h.db, req.Idpersona)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, errorResponse(err))
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, persona)
}

// Listar Personas
func (h *Handler) GetAllPersonas(ctx *gin.Context) {
	personas, err := dto.GetAllPersonas(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, personas)
}

// Eliminar Persona
func (h *Handler) DeletePersona(ctx *gin.Context) {
	idStr := ctx.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	err = dto.DeletePersona(h.db, int32(id))
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Persona eliminada correctamente"})
}

// Actualizar Persona
func (h *Handler) UpdatePersona(ctx *gin.Context) {
	var uri struct {
		Idpersona int32 `uri:"id" binding:"required"`
	}
	if err := ctx.ShouldBindUri(&uri); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	var req createPersonaRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	p := dto.Persona{
		IdPersona: uri.Idpersona,
		Nombre:    req.Nombre,
		Apellido1: req.Apellido1,
		Apellido2: req.Apellido2,
		FechaNac:  req.FechaNac,
		Direccion: req.Direccion,
		Telefono:  req.Telefono,
		Correo:    req.Correo,
	}
	err := dto.UpdatePersona(h.db, p)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Persona actualizada correctamente"})
}

func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
