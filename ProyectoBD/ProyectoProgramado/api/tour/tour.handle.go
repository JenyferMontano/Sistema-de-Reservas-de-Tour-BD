package tour

import (
	"ProyectoProgramadoI/dto"
	"context"
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"io"
	"os"
	"path/filepath"
	"strings"
)

type Handler struct {
	db *sql.DB
}

func NewHandler(db *sql.DB) *Handler {
	return &Handler{db: db}
}

type createTourRequest struct {
	Nombre         string  `json:"nombre" binding:"required"`
	Descripcion    string  `json:"descripcion" binding:"required"`
	Tipo           string  `json:"tipo" binding:"required"`
	Disponibilidad int8    `json:"disponibilidad" binding:"required"`
	Preciobase     float64 `json:"preciobase" binding:"required"`
	Ubicacion      string  `json:"ubicacion" binding:"required"`
	Imagetour      string  `json:"imagetour" binding:"required"`
}

func (h *Handler) CreateTour(ctx *gin.Context) {
	var req createTourRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	tour := dto.Tour{
		Nombre:         req.Nombre,
		Descripcion:    req.Descripcion,
		Tipo:           req.Tipo,
		Disponibilidad: req.Disponibilidad,
		Preciobase:     req.Preciobase,
		Ubicacion:      req.Ubicacion,
		Imagetour:      req.Imagetour,
	}

    err := dto.CreateTour(h.db, tour)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{
		"message": "Tour creado exitosamente",
		"tour":    tour,
	})
}

// Buscar por Id de tour
type getTourByIdRequest struct {
	Idtour int32 `uri:"id" binding:"required,min=1"`
}

func (h *Handler) GetTourById(ctx *gin.Context) {
	var req getTourByIdRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	tour, err := dto.GetTourById(h.db, req.Idtour)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, errorResponse(err))
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, tour)
}

// Buscar por tipo de tour, utilizar comboBox sino cambiar la funcion.
type getToursByTipoRequest struct {
	Tipo string `uri:"tipo" binding:"required"`
}

func (h *Handler) GetToursByTipo(ctx *gin.Context) {
	var req getToursByTipoRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	tours, err := dto.GetToursByTipo(h.db, req.Tipo)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, tours)
}

// Actualizar tours
type updateTourRequest struct {
	Nombre         string  `json:"nombre" binding:"required"`
	Descripcion    string  `json:"descripcion" binding:"required"`
	Tipo           string  `json:"tipo" binding:"required"`
	Disponibilidad int8    `json:"disponibilidad" binding:"required"`
	Preciobase     float64 `json:"preciobase" binding:"required"`
	Ubicacion      string  `json:"ubicacion" binding:"required"`
	Imagetour      string  `json:"imagetour" binding:"required"`
}

type updateTourUri struct {
	Idtour int32 `uri:"id" binding:"required,min=1"`
}

func (h *Handler) UpdateTour(ctx *gin.Context) {
	var uri updateTourUri
	if err := ctx.ShouldBindUri(&uri); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	var req updateTourRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	tour := dto.Tour{
		Idtour:         uri.Idtour,
		Nombre:         req.Nombre,
		Descripcion:    req.Descripcion,
		Tipo:           req.Tipo,
		Disponibilidad: req.Disponibilidad,
		Preciobase:     req.Preciobase,
		Ubicacion:      req.Ubicacion,
		Imagetour:      req.Imagetour,
	}
	err := dto.UpdateTour(h.db, tour)
	if err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	ctx.JSON(http.StatusOK, 
		gin.H{"message": "Tour actualizado exitosamente"})
}

// Eliminar tours...
type deleteTourRequest struct {
	Idtour int32 `uri:"id" binding:"required,min=1"`
}

func (h *Handler) DeleteTour(ctx *gin.Context) {
	var req deleteTourRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	err := dto.DeleteTour(h.db, req.Idtour)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{
				"message": "Tour no encontrado",
			})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{
		"message": "Tour eliminado exitosamente",
	})
}

// GETALL TOURS
type tourResponse struct {
	Idtour         int32   `json:"idtour"`
	Nombre         string  `json:"nombre"`
	Descripcion    string  `json:"descripcion"`
	Tipo           string  `json:"tipo"`
	Disponibilidad int8    `json:"disponibilidad"`
	Preciobase     float64 `json:"preciobase"`
	Ubicacion      string  `json:"ubicacion"`
	Imagetour      *string `json:"imagetour"`
}

func (h *Handler) GetAllTours(ctx *gin.Context) {
	tours, err := dto.GetAllTours(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var resp []tourResponse
	for _, t := range tours {
		var imagen *string
		if t.Imagetour != "" {
			imagen = &t.Imagetour
		}
		resp = append(resp, tourResponse{
			Idtour:         t.Idtour,
			Nombre:         t.Nombre,
			Descripcion:    t.Descripcion,
			Tipo:           t.Tipo,
			Disponibilidad: t.Disponibilidad,
			Preciobase:     t.Preciobase,
			Ubicacion:      t.Ubicacion,
			Imagetour:      imagen,
		})
	}
	ctx.JSON(http.StatusOK, resp)
}

func (h *Handler) uploadTourImg(ctx *gin.Context) {
	fileHeader, err := ctx.FormFile("file0")
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	allowedExt := map[string]bool{
		".png":  true,
		".jpg":  true,
		".jpeg": true,
	}
	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	if !allowedExt[ext] {
		ctx.JSON(http.StatusBadRequest, gin.H{"error": "Solo se permiten archivos PNG, JPG o JPEG"})
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	defer file.Close()

	uploadDir := "utils/images/tour"
	if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
		os.MkdirAll(uploadDir, os.ModePerm)
	}

	filename := uuid.New().String() + "_" + filepath.Base(fileHeader.Filename)
	fullPath := filepath.Join(uploadDir, filename)

	destinationFile, err := os.Create(fullPath)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	defer destinationFile.Close()

	_, err = io.Copy(destinationFile, file)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"file_name": filename,
		"message":   "Imagen del tour subida exitosamente",
	})
}

type GetTourImageRequest struct {
	Name string `uri:"name" binding:"required"`
}

func (h *Handler) getTourImg(ctx *gin.Context) {
	var req GetTourImageRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	filePath := filepath.Join("utils/images/tour", req.Name)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		ctx.JSON(http.StatusNotFound, gin.H{"error": "Imagen no encontrada"})
		return
	}

	ctx.File(filePath)
}


func (h *Handler) GetPrecioBaseTour(ctx context.Context, idTour int32) (float64, error) {
	precio, err := dto.GetTourByPrecioBase(h.db, idTour)
	if err != nil {
		return 0, err
	}
	return precio, nil
}


func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
