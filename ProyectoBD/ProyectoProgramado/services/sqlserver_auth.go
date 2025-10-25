package services

import (
	"database/sql"
	"fmt"
	"strings"
)

// SQLServerAuthService handles authentication against SQL Server users
type SQLServerAuthService struct {
	db *sql.DB
}

// NewSQLServerAuthService creates a new SQL Server authentication service
func NewSQLServerAuthService(db *sql.DB) *SQLServerAuthService {
	return &SQLServerAuthService{db: db}
}

// SQLServerUser represents a SQL Server user with their role mapping
type SQLServerUser struct {
	Username string
	Role     string
	Email    string // For compatibility with existing system
}

// AuthenticateSQLServerUser authenticates a user against SQL Server
// Returns the user info if authentication is successful, nil otherwise
func (s *SQLServerAuthService) AuthenticateSQLServerUser(username, password string) (*SQLServerUser, error) {
	roleMapping := map[string]string{
		"usuario_admin":       "DBA",      
		"usuario_restringido": "cliente",  
		"usuario_auditor":     "cliente",
	}
	
	// Check if the username is one of our predefined SQL Server users
	role, exists := roleMapping[username]
	if !exists {
		return nil, fmt.Errorf("usuario no encontrado")
	}
	
	// For now, we'll use a simple password validation
	// In a production environment, you would want to implement proper SQL Server authentication
	passwordMapping := map[string]string{
		"usuario_admin":       "AdminPass123!",
		"usuario_restringido": "RestrictedPass123!",
		"usuario_auditor":     "AuditorPass123!",
	}
	
	expectedPassword, exists := passwordMapping[username]
	if !exists || expectedPassword != password {
		return nil, fmt.Errorf("credenciales incorrectas")
	}
	
	// Create email for compatibility (using username as email for SQL Server users)
	email := fmt.Sprintf("%s@sqlserver.local", username)
	
	return &SQLServerUser{
		Username: username,
		Role:     role,
		Email:    email,
	}, nil
}

// IsSQLServerUser checks if a given email/username corresponds to a SQL Server user
func (s *SQLServerAuthService) IsSQLServerUser(emailOrUsername string) bool {
	sqlServerUsers := []string{"usuario_admin", "usuario_restringido", "usuario_auditor"}
	
	// Check if it's a direct username match
	for _, user := range sqlServerUsers {
		if strings.EqualFold(emailOrUsername, user) {
			return true
		}
	}
	
	// Check if it's an email format for SQL Server users
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

// ExtractUsernameFromEmail extracts username from email for SQL Server users
func (s *SQLServerAuthService) ExtractUsernameFromEmail(email string) string {
	if strings.HasSuffix(email, "@sqlserver.local") {
		return strings.TrimSuffix(email, "@sqlserver.local")
	}
	return email
}
