package middleware

import (
	"ProyectoProgramadoI/security"
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware(tokenBilder security.Builder) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		authHeader := ctx.GetHeader("authorization")
		if len(authHeader) == 0 {
			err := errors.New("falta token de autorización")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}
		fields := strings.Fields(authHeader)
		if len(fields) < 2 {
			err := errors.New("formato de token inválido")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}
		if strings.ToLower(fields[0]) != "bearer" {
			err := errors.New("tipo de autorización no soportado: 'bearer' requerido")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}
		accessToken := fields[1]
		payload, err := tokenBilder.VerifyToken(accessToken)
		if err != nil {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}
		ctx.Set("authorized", payload)
		ctx.Next()
	}
}

// Verifica el rol del usuario
func RequireRole(requiredRole string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		authorized, exists := ctx.Get("authorized")
		if !exists {
			err := errors.New("usuario no autenticado")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}
		payload, ok := authorized.(*security.Payload)
		if !ok {
			err := errors.New("información del usuario no válida")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}
		if payload.Rol != requiredRole {
			err := errors.New("acceso denegado: rol insuficiente")
			ctx.AbortWithStatusJSON(http.StatusForbidden, errorResponse(err))
			return
		}
		ctx.Next()
	}
}

// Verifica múltiples roles permitidos
func RequireRoles(allowedRoles ...string) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		authorized, exists := ctx.Get("authorized")
		if !exists {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(errors.New("usuario no autenticado")))
			return
		}

		payload, ok := authorized.(*security.Payload)
		if !ok {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(errors.New("información del usuario no válida")))
			return
		}

		for _, rol := range allowedRoles {
			if payload.Rol == rol {
				ctx.Next()
				return
			}
		}

		ctx.AbortWithStatusJSON(http.StatusForbidden, errorResponse(errors.New("acceso denegado: rol insuficiente")))
	}
}

// Middleware específico para operaciones de DBA (respaldo y restauración)
func RequireDBAPermissions() gin.HandlerFunc {
	return func(ctx *gin.Context) {
		authorized, exists := ctx.Get("authorized")
		if !exists {
			err := errors.New("usuario no autenticado")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}

		payload, ok := authorized.(*security.Payload)
		if !ok {
			err := errors.New("información del usuario no válida")
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, errorResponse(err))
			return
		}

		// Verificar que el usuario tenga rol de DBA
		if payload.Rol != "DBA" {
			err := errors.New("acceso denegado: Se requieren permisos de DBA para esta operación")
			ctx.AbortWithStatusJSON(http.StatusForbidden, errorResponse(err))
			return
		}

		ctx.Next()
	}
}

func errorResponse(err error) gin.H {
	return gin.H{
		"error": err.Error(),
	}
}
