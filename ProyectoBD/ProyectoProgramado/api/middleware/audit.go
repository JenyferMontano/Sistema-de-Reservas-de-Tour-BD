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
		// Obtener información del request
		endpoint := ctx.Request.URL.Path
		metodo := ctx.Request.Method
		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()

		// Procesar request
		ctx.Next()

		// Registrar auditoría después del procesamiento
		codigoRespuesta := ctx.Writer.Status()

		// Obtener información del usuario después del procesamiento
		userName := "anonymous"
		if authorized, exists := ctx.Get("authorized"); exists {
			if payload, ok := authorized.(*security.Payload); ok {
				userName = payload.Username
			}
		}

		// Registrar todos los endpoints excepto health check y archivos estáticos
		// Excluir login y logout que tienen middleware específicos
		if !strings.Contains(endpoint, "/health") &&
			!strings.Contains(endpoint, "/static") &&
			endpoint != "/api/v1/login" &&
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
		// Permitir acceso a login sin validación de sesión
		if ctx.Request.URL.Path == "/api/v1/login" {
			ctx.Next()
			return
		}

		// Solo validar si hay token de autorización
		authHeader := ctx.GetHeader("authorization")
		if len(authHeader) == 0 {
			ctx.Next()
			return
		}

		// Obtener información del usuario del token
		userName := "anonymous"
		if authorized, exists := ctx.Get("authorized"); exists {
			if payload, ok := authorized.(*security.Payload); ok {
				userName = payload.Username
			}
		}

		// Si es usuario anónimo, continuar
		if userName == "anonymous" {
			ctx.Next()
			return
		}

		// Verificar si el usuario tiene sesiones activas
		sessions, err := sessionService.GetActiveSessions(userName)
		if err != nil || len(sessions) == 0 {
			// No hay sesiones activas, denegar acceso
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
		// Obtener información del request antes del procesamiento
		endpoint := ctx.Request.URL.Path
		metodo := ctx.Request.Method
		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()

		// Procesar request
		ctx.Next()

		// Registrar acceso al endpoint de login
		codigoRespuesta := ctx.Writer.Status()
		go func() {
			auditService.LogAccess(
				"anonymous", // Usuario anónimo antes del login
				endpoint,
				metodo,
				ipAddress,
				userAgent,
				int32(codigoRespuesta),
			)
		}()

		// Verificar si el login fue exitoso (status 200)
		if ctx.Writer.Status() == http.StatusOK {
			// Obtener información del usuario del contexto
			if userName, exists := ctx.Get("login_user"); exists {
				if username, ok := userName.(string); ok {
					// Registrar inicio de sesión
					go func() {
						auditService.LogSessionStart(username, ipAddress, userAgent)
					}()

					// Crear sesión
					sessionID, err := sessionService.CreateSession(username, ipAddress, userAgent)
					if err == nil {
						// Agregar sessionID a la respuesta
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
		// Obtener información del request antes del procesamiento
		endpoint := ctx.Request.URL.Path
		metodo := ctx.Request.Method
		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()

		// Obtener información del usuario autenticado
		userName := "anonymous"
		if authorized, exists := ctx.Get("authorized"); exists {
			if payload, ok := authorized.(*security.Payload); ok {
				userName = payload.Username
			}
		}

		// Procesar logout
		ctx.Next()

		// Registrar acceso al endpoint de logout
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

		// Registrar cierre de sesión si fue exitoso
		if ctx.Writer.Status() == http.StatusOK && userName != "anonymous" {
			go func() {
				// Cerrar todas las sesiones del usuario
				err := sessionService.CloseAllUserSessions(userName)
				if err != nil {
					// Log error pero no fallar el logout
					return
				}

				// Registrar fin de sesión en auditoría
				err = auditService.LogSessionEnd(userName)
				if err != nil {
					// Log error pero no fallar el logout
					return
				}
			}()
		}
	}
}

// Función auxiliar para obtener IP del cliente
func getClientIP(ctx *gin.Context) string {
	// Intentar obtener IP real si hay proxy
	ip := ctx.GetHeader("X-Forwarded-For")
	if ip != "" {
		// Tomar la primera IP si hay múltiples
		ips := strings.Split(ip, ",")
		return strings.TrimSpace(ips[0])
	}

	ip = ctx.GetHeader("X-Real-IP")
	if ip != "" {
		return ip
	}

	// IP directa del cliente
	return ctx.ClientIP()
}
