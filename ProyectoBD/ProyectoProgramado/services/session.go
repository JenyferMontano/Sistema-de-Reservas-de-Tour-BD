package services

import (
	"database/sql"
	"time"
)

type SessionService struct {
	db *sql.DB
}

type Session struct {
	SessionID   string     `json:"sessionid"`
	UserName    string     `json:"username"`
	FechaInicio time.Time  `json:"fechainicio"`
	FechaFin    *time.Time `json:"fechafin"`
	IPAddress   string     `json:"ipaddress"`
	UserAgent   string     `json:"useragent"`
	Estado      string     `json:"estado"`
}

func NewSessionService(db *sql.DB) *SessionService {
	return &SessionService{db: db}
}

// Crear nueva sesión
func (s *SessionService) CreateSession(userName, ipAddress, userAgent string) (string, error) {
	var userAgentParam interface{} = nil
	if userAgent != "" {
		userAgentParam = userAgent
	}

	var sessionID string
	outputSessionID := sql.Out{Dest: &sessionID}
	
	_, err := s.db.Exec(
		"EXEC sp_create_session @p1, @p2, @p3, @sessionID OUTPUT",
		sql.Named("p1", userName),
		sql.Named("p2", ipAddress),
		sql.Named("p3", userAgentParam),
		sql.Named("sessionID", outputSessionID),
	)

	if err != nil {
		return "", err
	}

	return sessionID, nil
}

// Validar sesión
func (s *SessionService) ValidateSession(sessionID string) bool {
	var isValid bool
	outputIsValid := sql.Out{Dest: &isValid}

	_, err := s.db.Exec(
		"EXEC sp_validate_session @p1, @isValid OUTPUT",
		sql.Named("p1", sessionID),
		sql.Named("isValid", outputIsValid),
	)

	if err != nil {
		return false
	}

	return isValid
}

// Cerrar sesión
func (s *SessionService) CloseSession(sessionID string) error {
	_, err := s.db.Exec(
		"EXEC sp_close_session @p1",
		sql.Named("p1", sessionID),
	)
	return err
}

// Cerrar todas las sesiones de un usuario
func (s *SessionService) CloseAllUserSessions(userName string) error {
	_, err := s.db.Exec(
		"EXEC sp_close_all_user_sessions @p1",
		sql.Named("p1", userName),
	)
	return err
}

// Obtener sesiones activas de un usuario
func (s *SessionService) GetActiveSessions(userName string) ([]Session, error) {
	rows, err := s.db.Query(
		"EXEC sp_get_active_sessions @p1",
		sql.Named("p1", userName),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sessions []Session
	for rows.Next() {
		var session Session
		var minutosActiva sql.NullInt32

		err := rows.Scan(
			&session.SessionID,
			&session.UserName,
			&session.FechaInicio,
			&session.FechaFin,
			&session.IPAddress,
			&session.UserAgent,
			&session.Estado,
			&minutosActiva, 
		)
		if err != nil {
			return nil, err
		}
		sessions = append(sessions, session)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return sessions, nil
}
