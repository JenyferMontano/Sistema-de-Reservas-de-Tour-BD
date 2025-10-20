# Ejemplo de Integración de Auditoría en server.go

## Modificaciones Necesarias en server.go

```go
package api

import (
	detallefactura "ProyectoProgramadoI/api/detalleFactura"
	detallereserva "ProyectoProgramadoI/api/detalleReserva"
	"ProyectoProgramadoI/api/factura"
	"ProyectoProgramadoI/api/persona"
	"ProyectoProgramadoI/api/reserva"
	"ProyectoProgramadoI/api/tour"
	"ProyectoProgramadoI/api/usuario"
	"ProyectoProgramadoI/api/middleware"  // NUEVO: Importar middleware
	"ProyectoProgramadoI/services"          // NUEVO: Importar servicios
	"ProyectoProgramadoI/security"
	"database/sql"
	"time"

	"github.com/gin-gonic/gin"
	cors "github.com/itsjamie/gin-cors"
)

type Server struct {
	db            *sql.DB
	tokenBuilder  security.Builder
	tokenDuration time.Duration
	router        *gin.Engine
	// NUEVO: Agregar servicios de auditoría
	auditService   *services.AuditService
	sessionService *services.SessionService
}

func NewServer(db *sql.DB, tokenDuration time.Duration) (*Server, error) {
	tokenBuilder, err := security.NewPasetoBuilder("12345678123456781234567812345678")
	if err != nil {
		return nil, err
	}
	
	// NUEVO: Crear servicios de auditoría
	auditService := services.NewAuditService(db)
	sessionService := services.NewSessionService(db)
	
	server := &Server{
		db:            db,
		tokenBuilder:  tokenBuilder,
		tokenDuration: tokenDuration,
		auditService:  auditService,      // NUEVO
		sessionService: sessionService,  // NUEVO
	}
	
	router := gin.Default()
	
	// Middleware CORS
	router.Use(cors.Middleware(cors.Config{
		Origins:         "*",
		Methods:         "GET, PUT, POST, DELETE, OPTIONS",
		RequestHeaders:  "Origin, Authorization, Content-Type",
		ExposedHeaders:  "",
		MaxAge:          50 * time.Second,
		Credentials:     false,
		ValidateHeaders: false,
	}))
	
	// NUEVO: Agregar middleware de auditoría global
	router.Use(middleware.AuditMiddleware(auditService))
	router.Use(middleware.SessionValidationMiddleware(sessionService))
	
	usuarioHandler := usuario.NewHandler(db, tokenBuilder, tokenDuration)

	//RUTAS {ENDPOINTS} DEL API
	api := router.Group("/api/v1")
	api.GET("/tour/img/:name", tour.GetTourImgHandler(db))
	
	// NUEVO: Agregar middleware específico para login y logout
	api.POST("/login", middleware.LoginAuditMiddleware(auditService, sessionService), usuarioHandler.Login)
	api.POST("/logout", middleware.LogoutAuditMiddleware(auditService, sessionService), usuarioHandler.Logout)
	
	persona.RegisterRoutes(api.Group("/persona"), db, tokenBuilder)
	tour.RegisterRoutes(api.Group("/tour"), db, tokenBuilder)
	usuario.RegisterRoutes(api.Group("/usuario"), db, tokenBuilder, tokenDuration)
	detallereserva.RegisterRoutes(api.Group("/detallereserva"), db, tokenBuilder)
	reserva.RegisterRoutes(api.Group("/reserva"), db, tokenBuilder)
	factura.RegisterRoutes(api.Group("/factura"), db, tokenBuilder)
	detallefactura.RegisterRoutes(api.Group("/detallefactura"), db, tokenBuilder)

	///FIN RUTAS///
	server.router = router
	return server, nil
}

func (server *Server) Start(url string) error {
	return server.router.Run(url)
}
```

## Cambios Mínimos Requeridos

### 1. Importar los nuevos paquetes
```go
import (
    "ProyectoProgramadoI/api/middleware"  // NUEVO
    "ProyectoProgramadoI/services"        // NUEVO
    // ... otros imports existentes
)
```

### 2. Agregar servicios al struct Server
```go
type Server struct {
    db            *sql.DB
    tokenBuilder  security.Builder
    tokenDuration time.Duration
    router        *gin.Engine
    auditService   *services.AuditService    // NUEVO
    sessionService *services.SessionService  // NUEVO
}
```

### 3. Crear servicios en NewServer
```go
// NUEVO: Crear servicios de auditoría
auditService := services.NewAuditService(db)
sessionService := services.NewSessionService(db)
```

### 4. Agregar middleware global
```go
// NUEVO: Agregar middleware de auditoría global
router.Use(middleware.AuditMiddleware(auditService))
router.Use(middleware.SessionValidationMiddleware(sessionService))
```

### 5. Agregar middleware específico para login/logout
```go
// NUEVO: Agregar middleware específico para login y logout
api.POST("/login", middleware.LoginAuditMiddleware(auditService, sessionService), usuarioHandler.Login)
api.POST("/logout", middleware.LogoutAuditMiddleware(auditService, sessionService), usuarioHandler.Logout)
```

## Resultado

Con estos cambios mínimos:

1. **Todas las rutas** tendrán auditoría automática de accesos
2. **Login y logout** tendrán auditoría específica de sesiones
3. **Operaciones CRUD** se auditarán automáticamente con los triggers
4. **No se requiere** modificar ningún handler existente
5. **La auditoría** es completamente transparente

## Verificación

Para verificar que la auditoría funciona:

1. **Ejecutar el script de migración** para crear las tablas
2. **Hacer requests** a cualquier endpoint
3. **Consultar las tablas** de auditoría:
   ```sql
   SELECT * FROM auditoria_accesos;
   SELECT * FROM auditoria_operaciones;
   SELECT * FROM auditoria_sesiones;
   SELECT * FROM sesiones;
   ```

## Notas Importantes

- Los cambios son **mínimos** y **no rompen** el código existente
- La auditoría es **automática** y **transparente**
- No se requiere modificar **ningún handler** existente
- Los **triggers** se ejecutan automáticamente en la base de datos
- Los **middleware** se ejecutan automáticamente en el servidor
