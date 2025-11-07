package dto

import (
	"context"
	"database/sql"
)

func SetExecutorUser(ctx context.Context, db *sql.DB, userName string) error {
	if userName == "" {
		userName = "anonymous"
	}

	_, err := db.ExecContext(ctx, "EXEC sp_set_session_context @key = N'executor_user', @value = @p1", userName)
	return err
}

func SetExecutorUserTx(ctx context.Context, tx *sql.Tx, userName string) error {
	if userName == "" {
		userName = "anonymous"
	}
	
	_, err := tx.ExecContext(ctx, "EXEC sp_set_session_context @key = N'executor_user', @value = @p1", userName)
	return err
}

func GetExecutorUserFromGinContext() {
	
}

func ExecTransactionWithUser(db *sql.DB, ctx context.Context, userName string, fn func(tx *sql.Tx) error) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	
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

