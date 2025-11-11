package services

import (
	"database/sql"
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
		"EXEC sp_log_access @p1, @p2, @p3, @p4, @p5, @p6",
		sql.Named("p1", userName),
		sql.Named("p2", endpoint),
		sql.Named("p3", metodo),
		sql.Named("p4", codigoRespuesta),
		sql.Named("p5", ipAddress),
		sql.Named("p6", sql.NullString{String: userAgent, Valid: userAgent != ""}),
	)
	return err
}

type LogOperationOptions struct {
	Resultado string 
	SessionID string 
	IdAcceso  *int32 
}

func (s *AuditService) LogOperation(userName, tablaAfectada, operacion, ipAddress string, registroID string, valoresAnteriores, valoresNuevos string, opts *LogOperationOptions) error {
	// Valores por defecto
	var resultado, sessionID interface{} = nil, nil
	var idAcceso interface{} = nil

	if opts != nil {
		if opts.Resultado != "" {
			resultado = opts.Resultado
		} else {
			resultado = "EXITOSO"
		}
		if opts.SessionID != "" {
			sessionID = opts.SessionID
		}
		if opts.IdAcceso != nil {
			idAcceso = *opts.IdAcceso
		}
	} else {
		resultado = "EXITOSO"
	}

	_, err := s.db.Exec(
		"EXEC sp_log_operation @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @p9, @p10",
		sql.Named("p1", userName),
		sql.Named("p2", tablaAfectada),
		sql.Named("p3", operacion),
		sql.Named("p4", registroID),
		sql.Named("p5", sql.NullString{String: valoresAnteriores, Valid: valoresAnteriores != ""}),
		sql.Named("p6", sql.NullString{String: valoresNuevos, Valid: valoresNuevos != ""}),
		sql.Named("p7", ipAddress),
		sql.Named("p8", resultado),
		sql.Named("p9", sessionID),
		sql.Named("p10", idAcceso),
	)
	return err
}

// Registrar inicio de sesión
func (s *AuditService) LogSessionStart(userName, ipAddress, userAgent string) error {
	_, err := s.db.Exec(
		"EXEC sp_log_session_start @p1, @p2, @p3",
		sql.Named("p1", userName),
		sql.Named("p2", ipAddress),
		sql.Named("p3", sql.NullString{String: userAgent, Valid: userAgent != ""}),
	)
	return err
}

// Registrar fin de sesión
func (s *AuditService) LogSessionEnd(userName string) error {
	_, err := s.db.Exec(
		"EXEC sp_log_session_end @p1",
		sql.Named("p1", userName),
	)
	return err
}

// Registrar fin de sesión específica por sessionID
func (s *AuditService) LogSessionEndByID(sessionID string) error {
	_, err := s.db.Exec(
		"EXEC sp_log_session_end_by_id @p1",
		sql.Named("p1", sessionID),
	)
	return err
}
