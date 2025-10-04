package usuario

import (
	"ProyectoProgramadoI/dto"
	"ProyectoProgramadoI/security"
	"database/sql"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type Handler struct {
	db            *sql.DB
	tokenBuilder  security.Builder
	tokenDuration time.Duration
}

func NewHandler(db *sql.DB, tokenBuilder security.Builder, tokenDuration time.Duration) *Handler {
	return &Handler{db: db,
		tokenBuilder:  tokenBuilder,
		tokenDuration: tokenDuration}
}

type createUsuarioRequest struct {
	Username  string  `json:"username" binding:"required"`
	Password  string  `json:"password" binding:"required"`
	Rol       string  `json:"rol" binding:"required"`
	Idpersona int32   `json:"idpersona" binding:"required"`
	Image     *string `json:"image"`
}

func (h *Handler) CreateUsuario(ctx *gin.Context) {
	var req createUsuarioRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	var image sql.NullString
	if req.Image != nil && *req.Image != "" {
		image = sql.NullString{String: *req.Image, Valid: true}
	} else {
		image = sql.NullString{Valid: false}
	}

	usuario := dto.Usuario{
		Username:  req.Username,
		Password:  req.Password,
		Rol:       req.Rol,
		Idpersona: req.Idpersona,
		Image:     image,
	}

	err := dto.CreateUsuario(h.db, usuario)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"message": "Usuario creado exitosamente",
		"usuario": usuario,
	})
}

type updateUsuarioRequest struct {
	Password string  `json:"password"`
	Image    *string `json:"image"`
}

type updateUsuarioUri struct {
	Username string `uri:"username" binding:"required"`
}

func (h *Handler) UpdateUsuario(ctx *gin.Context) {
	var uri updateUsuarioUri
	if err := ctx.ShouldBindUri(&uri); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	var req updateUsuarioRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}

	userActual, err := dto.GetUsuarioByUserName(h.db, uri.Username)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}

	passwordToUpdate := req.Password
	if passwordToUpdate == "" {
		passwordToUpdate = userActual.Password
	}

	var image sql.NullString

	if req.Image != nil && *req.Image != "" {
		image = sql.NullString{String: *req.Image, Valid: true}

		if userActual.Image.Valid && userActual.Image.String != *req.Image {
			oldImagePath := filepath.Join("utils/images/usuarios", userActual.Image.String)
			if err := os.Remove(oldImagePath); err != nil && !os.IsNotExist(err) {
				ctx.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo eliminar la imagen anterior"})
				return
			}
		}
	} else {
		image = userActual.Image
	}

	args := dto.UpdateUsuarioParams{
		Password: passwordToUpdate,
		Image:    image,
		Username: uri.Username,
	}

	err = dto.UpdateUsuario(h.db, args)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Usuario actualizado exitosamente!"})

}

/*
// Actualizar contraseña  e imagen de usuario
type updateUsuarioRequest struct {
	Password string  `json:"password"`
	Image    *string `json:"image"`
}

type updateUsuarioUri struct {
	Username string `uri:"username" binding:"required"`
}

func (h *Handler) UpdateUsuario(ctx *gin.Context) {
	var uri updateUsuarioUri
	if err := ctx.ShouldBindUri(&uri); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	var req updateUsuarioRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	userActual, err := dto.GetUsuarioByUserName(h.db, uri.Username)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	passwordToUpdate := req.Password
	if passwordToUpdate == "" {
		passwordToUpdate = userActual.Password
	}
	var image sql.NullString
	if req.Image != nil && *req.Image != "" {
		image = sql.NullString{String: *req.Image, Valid: true}
		if userActual.Image.Valid && userActual.Image.String != *req.Image {
			oldImagePath := filepath.Join("utils/images/usuarios", userActual.Image.String)
			if err := os.Remove(oldImagePath); err != nil && !os.IsNotExist(err) {
				ctx.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo eliminar la imagen anterior"})
				return
			}
		}
	} else {
		image = userActual.Image
	}
	usuario := dto.Usuario{
		Username:  uri.Username,
		Password:  passwordToUpdate,
		Rol:       userActual.Rol,
		Idpersona: userActual.Idpersona,
		Image:     image,
	}
	err = dto.UpdateUsuario(h.db, usuario)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Usuario actualizado exitosamente!"})

}

*/

// Buscar por username
type usuarioResponse struct {
	Username  string  `json:"username"`
	Rol       string  `json:"rol"`
	Idpersona int32   `json:"idpersona"`
	Image     *string `json:"image"`
}
type getUsuarioByUsernameRequest struct {
	Username string `uri:"username" binding:"required"`
}

func (h *Handler) GetUsuarioByUsername(ctx *gin.Context) {
	var req getUsuarioByUsernameRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	usuario, err := dto.GetUsuarioByUserName(h.db, req.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"message": "Usuario no encontrado"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var image *string
	if usuario.Image.Valid {
		image = &usuario.Image.String
	}
	resp := usuarioResponse{
		Username:  usuario.Username,
		Rol:       usuario.Rol,
		Idpersona: usuario.Idpersona,
		Image:     image,
	}
	ctx.JSON(http.StatusOK, resp)
}

// Eliminar usuarios...
type deleteUsuarioRequest struct {
	Username string `uri:"username" binding:"required"`
}

func (h *Handler) DeleteUsuario(ctx *gin.Context) {
	var req deleteUsuarioRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	usuario, err := dto.GetUsuarioByUserName(h.db, req.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusNotFound, gin.H{"message": "Usuario no encontrado"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if usuario.Image.Valid {
		imagePath := filepath.Join("utils/images/usuarios", usuario.Image.String)
		if err := os.Remove(imagePath); err != nil && !os.IsNotExist(err) {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": "Error al eliminar la imagen: " + err.Error()})
			return
		}
	}
	err = dto.DeleteUsuario(h.db, req.Username)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"message": "Usuario eliminado exitosamente"})

}

// Obtener todos los usuarios para admin
func (h *Handler) GetAllUsuarios(ctx *gin.Context) {
	usuarios, err := dto.GetAllUsuarios(h.db)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var resp []usuarioResponse
	for _, u := range usuarios {
		var image *string
		if u.Image.Valid {
			image = &u.Image.String
		}
		resp = append(resp, usuarioResponse{
			Username:  u.Username,
			Rol:       u.Rol,
			Idpersona: u.Idpersona,
			Image:     image,
		})
	}
	ctx.JSON(http.StatusOK, resp)
}

// Login de usuario
type loginRequest struct {
	Email    string `json:"email" binding:"required"`
	Password string `json:"password" binding:"required"`
}
type loginResponse struct {
	AccessToken string       `json:"access_token"`
	User        userResponse `json:"user"`
}
type userResponse struct {
	UserName string  `json:"username"`
	Role     string  `json:"role"`
	Image    *string `json:"image"`
}

func (h *Handler) Login(ctx *gin.Context) {
	var req loginRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	user, err := dto.GetUsuarioByCorreo(h.db, req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Correo o contraseña incorrectos"})
			return
		}
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	if user.Password != req.Password {
		ctx.JSON(http.StatusUnauthorized, gin.H{"error": "Usuario no autorizado"})
		return
	}
	accessToken, err := h.tokenBuilder.CreateToken(user.Username, req.Email, user.Rol, h.tokenDuration)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	var image *string
	if user.Image.Valid {
		image = &user.Image.String
	}
	resp := loginResponse{
		AccessToken: accessToken,
		User: userResponse{
			UserName: user.Username,
			Role:     user.Rol,
			Image:    image,
		},
	}
	ctx.JSON(http.StatusOK, resp)
}

func (h *Handler) uploadUsuarioImg(ctx *gin.Context) {
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
	uploadDir := "utils/images/usuarios"
	if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
		ctx.JSON(http.StatusInternalServerError, errorResponse(err))
		return
	}
	filename := uuid.New().String() + "_" + filepath.Base(fileHeader.Filename)
	destinationFile, err := os.Create(filepath.Join(uploadDir, filename))
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
		"message":   "Archivo cargado exitosamente",
	})
}

type GetUsuarioImageRequest struct {
	Name string `uri:"name" binding:"required"`
}

func (h *Handler) getUsuarioImg(ctx *gin.Context) {
	var req GetUsuarioImageRequest
	if err := ctx.ShouldBindUri(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, errorResponse(err))
		return
	}
	fileUrl := "utils/images/usuarios/" + req.Name
	ctx.File(fileUrl)
}

func errorResponse(err error) gin.H {
	return gin.H{"error": err.Error()}
}
