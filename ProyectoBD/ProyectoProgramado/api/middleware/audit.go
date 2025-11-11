package middleware

import (
	"ProyectoProgramadoI/security"
	"ProyectoProgramadoI/services"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// Middleware de auditoría para registrar accesos a endpoints
func AuditMiddleware(auditService *services.AuditService) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		endpoint := ctx.Request.URL.Path
		metodo := ctx.Request.Method
		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()

		ctx.Next()

		codigoRespuesta := ctx.Writer.Status()

		userName := "anonymous"

		if endpoint == "/api/v1/login" {
			if loginUser, exists := ctx.Get("login_user"); exists {
				if username, ok := loginUser.(string); ok {
					userName = username
				}
			}
		} else {
			if authorized, exists := ctx.Get("authorized"); exists {
				if payload, ok := authorized.(*security.Payload); ok {
					userName = payload.Username
				}
			}
		}


		if !strings.Contains(endpoint, "/health") &&
			!strings.Contains(endpoint, "/static") &&
			endpoint != "/api/v1/logout" {
			go func() {
				auditService.LogAccess(
					userName,
					endpoint,
					metodo,
					ipAddress,
					userAgent,
					int32(codigoRespuesta),
				)
			}()
		}
	}
}

// Middleware para validar sesiones
func SessionValidationMiddleware(sessionService *services.SessionService) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		if ctx.Request.URL.Path == "/api/v1/login" {
			ctx.Next()
			return
		}

		authHeader := ctx.GetHeader("authorization")
		if len(authHeader) == 0 {
			ctx.Next()
			return
		}

		userName := "anonymous"
		if authorized, exists := ctx.Get("authorized"); exists {
			if payload, ok := authorized.(*security.Payload); ok {
				userName = payload.Username
			}
		}

		if userName == "anonymous" {
			ctx.Next()
			return
		}

		sessions, err := sessionService.GetActiveSessions(userName)
		if err != nil || len(sessions) == 0 {

			ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Sesión inválida o expirada. Por favor, inicie sesión nuevamente.",
			})
			return
		}

		ctx.Next()
	}
}

// Middleware para registrar inicio de sesión
func LoginAuditMiddleware(auditService *services.AuditService, sessionService *services.SessionService) gin.HandlerFunc {
	return func(ctx *gin.Context) {

		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()

		ctx.Next()

		if ctx.Writer.Status() == http.StatusOK {
			if userName, exists := ctx.Get("login_user"); exists {
				if username, ok := userName.(string); ok {
					// Registrar inicio de sesión
					go func() {
						auditService.LogSessionStart(username, ipAddress, userAgent)
					}()
					sessionID, err := sessionService.CreateSession(username, ipAddress, userAgent)
					if err == nil {
						ctx.Header("x-session-id", sessionID)
					}
				}
			}
		}
	}
}

// Middleware para registrar cierre de sesión
func LogoutAuditMiddleware(auditService *services.AuditService, sessionService *services.SessionService) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		endpoint := ctx.Request.URL.Path
		metodo := ctx.Request.Method
		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()

		userName := "anonymous"
		if authorized, exists := ctx.Get("authorized"); exists {
			if payload, ok := authorized.(*security.Payload); ok {
				userName = payload.Username
			}
		}

		ctx.Next()

		// Registrar acceso al endpoint logout
		codigoRespuesta := ctx.Writer.Status()
		go func() {
			auditService.LogAccess(
				userName,
				endpoint,
				metodo,
				ipAddress,
				userAgent,
				int32(codigoRespuesta),
			)
		}()

		// Registrar cierre de sesión
		if ctx.Writer.Status() == http.StatusOK && userName != "anonymous" {
			go func() {
				err := sessionService.CloseAllUserSessions(userName)
				if err != nil {
					return
				}

				// Registrar fin de sesión
				err = auditService.LogSessionEnd(userName)
				if err != nil {
					return
				}
			}()
		}
	}
}

// Obtener IP del cliente
func getClientIP(ctx *gin.Context) string {
	ip := ctx.GetHeader("X-Forwarded-For")
	if ip != "" {
		ips := strings.Split(ip, ",")
		return strings.TrimSpace(ips[0])
	}

	ip = ctx.GetHeader("X-Real-IP")
	if ip != "" {
		return ip
	}

	return ctx.ClientIP()
}
