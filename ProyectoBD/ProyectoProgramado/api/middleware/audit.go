package middleware

import (
	"ProyectoProgramadoI/services"
	"ProyectoProgramadoI/security"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// Middleware de auditoría para registrar accesos a endpoints
func AuditMiddleware(auditService *services.AuditService) gin.HandlerFunc {
	return func(ctx *gin.Context) {
		// Obtener información del request
		userName := "anonymous"
		if authorized, exists := ctx.Get("authorized"); exists {
			if payload, ok := authorized.(*security.Payload); ok {
				userName = payload.Username
			}
		}
		
		endpoint := ctx.Request.URL.Path
		metodo := ctx.Request.Method
		ipAddress := getClientIP(ctx)
		userAgent := ctx.Request.UserAgent()
		
		// Procesar request
		ctx.Next()
		
		// Registrar auditoría después del procesamiento
		codigoRespuesta := ctx.Writer.Status()
		
		// Solo registrar si no es una petición de health check, estática o login/logout (estos tienen middleware específico)
		if !strings.Contains(endpoint, "/health") && 
		   !strings.Contains(endpoint, "/static") && 
		   !strings.Contains(endpoint, "/login") && 
		   !strings.Contains(endpoint, "/logout") {
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
		// Solo validar si hay token de autorización
		authHeader := ctx.GetHeader("authorization")
		if len(authHeader) == 0 {
			ctx.Next()
			return
		}
		
		// Extraer sessionID del token (esto dependería de tu implementación de tokens)
		sessionID := ctx.GetHeader("x-session-id")
		if sessionID == "" {
			ctx.Next()
			return
		}
		
		// Validar sesión
		if !sessionService.ValidateSession(sessionID) {
			ctx.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"error": "Sesión inválida o expirada",
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
		sessionID := ctx.GetHeader("x-session-id")
		
		// Obtener información del usuario antes del logout
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
		if ctx.Writer.Status() == http.StatusOK {
			go func() {
				auditService.LogSessionEnd(userName)
				if sessionID != "" {
					sessionService.CloseSession(sessionID)
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