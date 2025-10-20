package services

import (
	"database/sql"
	"time"
)

type AuditService struct {
	db *sql.DB
}

func NewAuditService(db *sql.DB) *AuditService {
	return &AuditService{db: db}
}

// Registrar acceso a endpoint
func (s *AuditService) LogAccess(userName, endpoint, metodo, ipAddress, userAgent string, codigoRespuesta int32) error {
	_, err := s.db.Exec(
		"INSERT INTO auditoria_accesos (userName, endpoint, metodo, codigoRespuesta, ipAddress, userAgent) VALUES (?, ?, ?, ?, ?, ?)",
		userName, endpoint, metodo, codigoRespuesta, ipAddress, userAgent,
	)
	return err
}

// Registrar operación CRUD
func (s *AuditService) LogOperation(userName, tablaAfectada, operacion, ipAddress string, registroID int32, valoresAnteriores, valoresNuevos string) error {
	_, err := s.db.Exec(
		"INSERT INTO auditoria_operaciones (userName, tablaAfectada, operacion, registroId, valoresAnteriores, valoresNuevos, ipAddress) VALUES (?, ?, ?, ?, ?, ?, ?)",
		userName, tablaAfectada, operacion, registroID, valoresAnteriores, valoresNuevos, ipAddress,
	)
	return err
}

// Registrar inicio de sesión
func (s *AuditService) LogSessionStart(userName, ipAddress, userAgent string) error {
	_, err := s.db.Exec(
		"INSERT INTO auditoria_sesiones (userName, fechaInicio, ipAddress, userAgent, estado) VALUES (?, ?, ?, ?, ?)",
		userName, time.Now(), ipAddress, userAgent, "ACTIVA",
	)
	return err
}

// Registrar fin de sesión
func (s *AuditService) LogSessionEnd(userName string) error {
	_, err := s.db.Exec(
		"UPDATE auditoria_sesiones SET fechaFin = ?, estado = ? WHERE userName = ? AND estado = 'ACTIVA'",
		time.Now(), "CERRADA", userName,
	)
	return err
}