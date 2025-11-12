package main

import (
	"ProyectoProgramadoI/api"
	"ProyectoProgramadoI/utils"
	"database/sql"
	"log"
	"os"
	"time"

	_ "github.com/microsoft/go-mssqldb"
)

func main() {
	config, err := utils.LoadConfig(".")
	if err != nil {
		log.Fatal("No se pudo cargar el archivo de configuración:", err)
	}

	tokenDuration, err := time.ParseDuration(config.TokenDuration)
	if err != nil {
		log.Fatal("Duración del token inválida:", err)
	}

	conn, err := sql.Open(config.DBDriver, config.DBSource)
	if err != nil {
		log.Fatal("No se puede establecer la conexión:", err)
	}

	server, err := api.NewServer(conn, tokenDuration)
	if err != nil {
		log.Fatal("No se puede iniciar el servidor:", err)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	addr := "0.0.0.0:" + port
	log.Println("Escuchando en", addr)

	if err := server.Start(addr); err != nil {
		log.Fatal("No se puede iniciar el servidor:", err)
	}
}
