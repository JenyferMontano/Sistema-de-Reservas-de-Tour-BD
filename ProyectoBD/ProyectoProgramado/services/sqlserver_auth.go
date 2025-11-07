package services

import (
	"database/sql"
	"fmt"
	"strings"
)

type SQLServerAuthService struct {
	db *sql.DB
}

func NewSQLServerAuthService(db *sql.DB) *SQLServerAuthService {
	return &SQLServerAuthService{db: db}
}

type SQLServerUser struct {
	Username string
	Role     string
	Email    string 
}


func (s *SQLServerAuthService) AuthenticateSQLServerUser(username, password string) (*SQLServerUser, error) {
	roleMapping := map[string]string{
		"usuario_admin":       "DBA",      
		"usuario_restringido": "cliente",
	}
	
	role, exists := roleMapping[username]
	if !exists {
		return nil, fmt.Errorf("usuario no encontrado")
	}
	
	passwordMapping := map[string]string{
		"usuario_admin":       "Xy@78kM!23zQ",
		"usuario_restringido": "RestrictedPass123!",
	}
	
	expectedPassword, exists := passwordMapping[username]
	if !exists || expectedPassword != password {
		return nil, fmt.Errorf("credenciales incorrectas")
	}
	
	email := fmt.Sprintf("%s@sqlserver.local", username)
	
	return &SQLServerUser{
		Username: username,
		Role:     role,
		Email:    email,
	}, nil
}

func (s *SQLServerAuthService) IsSQLServerUser(emailOrUsername string) bool {
	sqlServerUsers := []string{"usuario_admin", "usuario_restringido"}

	for _, user := range sqlServerUsers {
		if strings.EqualFold(emailOrUsername, user) {
			return true
		}
	}
	
	if strings.HasSuffix(emailOrUsername, "@sqlserver.local") {
		username := strings.TrimSuffix(emailOrUsername, "@sqlserver.local")
		for _, user := range sqlServerUsers {
			if strings.EqualFold(username, user) {
				return true
			}
		}
	}
	
	return false
}


func (s *SQLServerAuthService) ExtractUsernameFromEmail(email string) string {
	if strings.HasSuffix(email, "@sqlserver.local") {
		return strings.TrimSuffix(email, "@sqlserver.local")
	}
	return email
}
