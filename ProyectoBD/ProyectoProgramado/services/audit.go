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

// Registrar acceso a endpoint usando procedimiento almacenado
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

// LogOperationOptions contiene parámetros opcionales para LogOperation
type LogOperationOptions struct {
	Resultado string // "EXITOSO", "FALLIDO", "PENDIENTE"
	SessionID string // ID de sesión (se obtiene automáticamente si es NULL)
	IdAcceso  *int32 // ID de acceso (se obtiene automáticamente si es NULL)
}

// Registrar operación CRUD usando procedimiento almacenado
// Los parámetros opcionales pueden pasarse a través de LogOperationOptions
// Si opts es nil, se usarán valores por defecto (resultado = "EXITOSO")
// sessionID e idAcceso se obtendrán automáticamente desde las tablas relacionadas si son NULL
func (s *AuditService) LogOperation(userName, tablaAfectada, operacion, ipAddress string, registroID string, valoresAnteriores, valoresNuevos string, opts *LogOperationOptions) error {
	// Valores por defecto
	var resultado, sessionID interface{} = nil, nil
	var idAcceso interface{} = nil

	// Procesar opciones si se proporcionan
	if opts != nil {
		if opts.Resultado != "" {
			resultado = opts.Resultado
		} else {
			// Valor por defecto para resultado
			resultado = "EXITOSO"
		}
		if opts.SessionID != "" {
			sessionID = opts.SessionID
		}
		if opts.IdAcceso != nil {
			idAcceso = *opts.IdAcceso
		}
	} else {
		// Si no se proporcionan opciones, usar resultado por defecto
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

// Registrar inicio de sesión usando procedimiento almacenado
func (s *AuditService) LogSessionStart(userName, ipAddress, userAgent string) error {
	_, err := s.db.Exec(
		"EXEC sp_log_session_start @p1, @p2, @p3",
		sql.Named("p1", userName),
		sql.Named("p2", ipAddress),
		sql.Named("p3", sql.NullString{String: userAgent, Valid: userAgent != ""}),
	)
	return err
}

// Registrar fin de sesión usando procedimiento almacenado
func (s *AuditService) LogSessionEnd(userName string) error {
	_, err := s.db.Exec(
		"EXEC sp_log_session_end @p1",
		sql.Named("p1", userName),
	)
	return err
}

// Registrar fin de sesión específica por sessionID usando procedimiento almacenado
func (s *AuditService) LogSessionEndByID(sessionID string) error {
	_, err := s.db.Exec(
		"EXEC sp_log_session_end_by_id @p1",
		sql.Named("p1", sessionID),
	)
	return err
}
