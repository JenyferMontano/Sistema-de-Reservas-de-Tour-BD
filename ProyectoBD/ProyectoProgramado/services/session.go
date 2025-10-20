package services

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
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
	sessionID := uuid.New().String()

	_, err := s.db.Exec(
		"EXEC pa_sesion_create @sessionID=@p1, @userName=@p2, @ipAddress=@p3, @userAgent=@p4, @estado=@p5",
		sessionID, userName, ipAddress, userAgent, "ACTIVA",
	)

	if err != nil {
		return "", err
	}

	return sessionID, nil
}

// Validar sesión
func (s *SessionService) ValidateSession(sessionID string) bool {
	var count int32
	err := s.db.QueryRow("EXEC pa_sesion_validate @sessionID=@p1", sessionID).Scan(&count)
	if err != nil {
		return false
	}
	return count > 0
}

// Cerrar sesión
func (s *SessionService) CloseSession(sessionID string) error {
	_, err := s.db.Exec(
		"EXEC pa_sesion_close @sessionID=@p1, @fechaFin=@p2, @estado=@p3",
		sessionID, time.Now(), "CERRADA",
	)
	return err
}

// Cerrar todas las sesiones de un usuario
func (s *SessionService) CloseAllUserSessions(userName string) error {
	_, err := s.db.Exec(
		"UPDATE sesiones SET fechaFin = ?, estado = ? WHERE userName = ? AND estado = 'ACTIVA'",
		time.Now(), "CERRADA", userName,
	)
	return err
}

// Obtener sesiones activas de un usuario
func (s *SessionService) GetActiveSessions(userName string) ([]Session, error) {
	rows, err := s.db.Query(
		"SELECT sessionID, userName, fechaInicio, fechaFin, ipAddress, userAgent, estado FROM sesiones WHERE userName = ? AND estado = 'ACTIVA'",
		userName,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sessions []Session
	for rows.Next() {
		var session Session
		err := rows.Scan(&session.SessionID, &session.UserName, &session.FechaInicio, &session.FechaFin, &session.IPAddress, &session.UserAgent, &session.Estado)
		if err != nil {
			return nil, err
		}
		sessions = append(sessions, session)
	}

	return sessions, nil
}
