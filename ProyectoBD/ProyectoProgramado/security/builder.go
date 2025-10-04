package security

import "time"

type Builder interface {
	CreateToken(username string, email string, rol string, duration time.Duration) (string, error)
	VerifyToken(token string) (*Payload, error)
}
