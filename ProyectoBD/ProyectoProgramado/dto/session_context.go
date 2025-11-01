package dto

import (
	"context"
	"database/sql"
)

// SetExecutorUser establece el usuario ejecutor en SESSION_CONTEXT de SQL Server
// Esto permite que los triggers identifiquen quién ejecutó la operación
func SetExecutorUser(ctx context.Context, db *sql.DB, userName string) error {
	if userName == "" {
		userName = "anonymous"
	}
	
	// Establecer SESSION_CONTEXT en SQL Server
	_, err := db.ExecContext(ctx, "EXEC sp_set_session_context @key = N'executor_user', @value = @p1", userName)
	return err
}

// SetExecutorUserTx establece el usuario ejecutor en SESSION_CONTEXT dentro de una transacción
func SetExecutorUserTx(ctx context.Context, tx *sql.Tx, userName string) error {
	if userName == "" {
		userName = "anonymous"
	}
	
	// Establecer SESSION_CONTEXT en SQL Server dentro de la transacción
	_, err := tx.ExecContext(ctx, "EXEC sp_set_session_context @key = N'executor_user', @value = @p1", userName)
	return err
}

// GetExecutorUserFromGinContext es una función helper que extrae el userName del contexto de Gin
// Debe ser usada en los handlers para obtener el usuario autenticado
// Ejemplo:
//   userName := GetExecutorUserFromGinContext(ctx)
//   SetExecutorUser(ctx.Request.Context(), db, userName)
//
// O usar directamente:
//   userName := "anonymous"
//   if authorized, exists := ctx.Get("authorized"); exists {
//       if payload, ok := authorized.(*security.Payload); ok {
//           userName = payload.Username
//       }
//   }
//   SetExecutorUser(ctx.Request.Context(), db, userName)
func GetExecutorUserFromGinContext() {
	// Esta función es solo para documentación
	// Los handlers deben extraer el usuario manualmente usando ctx.Get()
}

// ExecTransactionWithUser ejecuta una transacción estableciendo el usuario ejecutor en SESSION_CONTEXT
func ExecTransactionWithUser(db *sql.DB, ctx context.Context, userName string, fn func(tx *sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	
	// Establecer SESSION_CONTEXT antes de ejecutar la función
	if err := SetExecutorUserTx(ctx, tx, userName); err != nil {
		tx.Rollback()
		return err
	}
	
	err = fn(tx)
	if err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return err
		}
		return err
	}
	return tx.Commit()
}

