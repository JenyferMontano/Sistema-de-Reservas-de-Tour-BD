package api

import (
	detallefactura "ProyectoProgramadoI/api/detalleFactura"
	detallereserva "ProyectoProgramadoI/api/detalleReserva"
	"ProyectoProgramadoI/api/factura"
	"ProyectoProgramadoI/api/persona"
	"ProyectoProgramadoI/api/reserva"
	"ProyectoProgramadoI/api/tour"
	"ProyectoProgramadoI/api/usuario"
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
}

func NewServer(db *sql.DB, tokenDuration time.Duration) (*Server, error) {
	tokenBuilder, err := security.NewPasetoBuilder("12345678123456781234567812345678")
	if err != nil {
		return nil, err
	}
	server := &Server{
		db:            db,
		tokenBuilder:  tokenBuilder,
		tokenDuration: tokenDuration,
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
	usuarioHandler := usuario.NewHandler(db, tokenBuilder, tokenDuration)

	//RUTAS {ENDPOINTS} DEL API
	api := router.Group("/api/v1")
	api.GET("/tour/img/:name", tour.GetTourImgHandler(db))
	api.POST("/login", usuarioHandler.Login)
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
