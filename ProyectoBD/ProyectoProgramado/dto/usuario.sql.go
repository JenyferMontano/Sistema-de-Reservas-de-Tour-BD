package dto

import (
	"database/sql"
)

// Funciones CRUD para Usuario usando SQL Server

func CreateUsuario(db *sql.DB, u Usuario) error {
	_, err := db.Exec(
		"EXEC pa_usuario_insert @userName=@p1, @password=@p2, @idPersona=@p3, @rol=@p4, @image=@p5",
		u.Username, u.Password, u.Idpersona, u.Rol, u.Image,
	)
	return err
}

/*
func CreateUsuario(db *sql.DB, u Usuario) error {
	_, err := db.Exec(
		"INSERT INTO Usuario (userName, password, rol, idPersona, image) VALUES (@p1, @p2, @p3, @p4, @p5)",
		u.Username, u.Password, u.Rol, u.Idpersona, u.Image,
	)
	return err
}*/

func DeleteUsuario(db *sql.DB, username string) error {
	_, err := db.Exec(
		"EXEC pa_usuario_delete @userName=@p1",
		username,
	)
	return err
}

/*
func DeleteUsuario(db *sql.DB, username string) error {
	_, err := db.Exec("DELETE FROM Usuario WHERE userName = @p1", username)
	return err
}*/

type GetAllUsuariosRow struct {
	Username  string         `json:"username"`
	Rol       string         `json:"rol"`
	Idpersona int32          `json:"idpersona"`
	Image     sql.NullString `json:"image"`
}

func GetAllUsuarios(db *sql.DB) ([]GetAllUsuariosRow, error) {
	// Llamamos al procedimiento almacenado sin filtrar
	rows, err := db.Query("EXEC pa_usuario_getAll @userName = NULL")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var usuarios []GetAllUsuariosRow
	for rows.Next() {
		var u GetAllUsuariosRow
		var password string
		err := rows.Scan(&u.Username, &password, &u.Idpersona, &u.Rol, &u.Image)
		if err != nil {
			return nil, err
		}

		usuarios = append(usuarios, u)
	}

	return usuarios, nil
}

/*
func GetAllUsuarios(db *sql.DB) ([]Usuario, error) {
	rows, err := db.Query("SELECT userName, password, rol, idPersona, image FROM Usuario")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var usuarios []Usuario
	for rows.Next() {
		var u Usuario
		err := rows.Scan(&u.Username, &u.Password, &u.Rol, &u.Idpersona, &u.Image)
		if err != nil {
			return nil, err
		}
		usuarios = append(usuarios, u)
	}
	return usuarios, nil
}
*/

func GetCorreoByUserName(db *sql.DB, username string) (string, error) {
	row := db.QueryRow("EXEC pa_usuario_getCorreoByUserName @userName = @p1", username)
	var correo string
	err := row.Scan(&correo)
	return correo, err
}

/*
func GetCorreoByUserName(db *sql.DB, username string) (string, error) {
	row := db.QueryRow("SELECT p.correo FROM Usuario u JOIN Persona p ON u.idPersona = p.idPersona WHERE u.userName = @p1", username)
	var correo string
	err := row.Scan(&correo)
	return correo, err
}*/

type GetUsuarioByCorreoRow struct {
	Username  string         `json:"username"`
	Password  string         `json:"password"`
	Rol       string         `json:"rol"`
	Idpersona int32          `json:"idpersona"`
	Image     sql.NullString `json:"image"`
}

func GetUsuarioByCorreo(db *sql.DB, correo string) (*GetUsuarioByCorreoRow, error) {
	row := db.QueryRow("EXEC pa_usuario_getByCorreo @correo = @p1", correo)
	var u GetUsuarioByCorreoRow
	err := row.Scan(&u.Username, &u.Password, &u.Rol, &u.Idpersona, &u.Image)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

/*
func GetUsuarioByCorreo(db *sql.DB, correo string) (*Usuario, error) {
	row := db.QueryRow("SELECT u.userName, u.password, u.rol, u.idPersona, u.image FROM Usuario u JOIN Persona p ON u.idPersona = p.idPersona WHERE p.correo = @p1", correo)
	var u Usuario
	err := row.Scan(&u.Username, &u.Password, &u.Rol, &u.Idpersona, &u.Image)
	if err != nil {
		return nil, err
	}
	return &u, nil
}*/

type GetUsuarioByUserNameRow struct {
	Username  string         `json:"username"`
	Password  string         `json:"password"`
	Rol       string         `json:"rol"`
	Idpersona int32          `json:"idpersona"`
	Image     sql.NullString `json:"image"`
}

func GetUsuarioByUserName(db *sql.DB, username string) (*GetUsuarioByUserNameRow, error) {
	row := db.QueryRow("EXEC pa_usuario_getByUserName @userName = @p1", username)
	var u GetUsuarioByUserNameRow
	err := row.Scan(&u.Username, &u.Password, &u.Rol, &u.Idpersona, &u.Image)
	if err != nil {
		return nil, err
	}
	return &u, nil
}

/*
func GetUsuarioByUserName(db *sql.DB, username string) (*Usuario, error) {
	row := db.QueryRow("SELECT userName, password, rol, idPersona, image FROM Usuario WHERE userName = @p1", username)
	var u Usuario
	err := row.Scan(&u.Username, &u.Password, &u.Rol, &u.Idpersona, &u.Image)
	if err != nil {
		return nil, err
	}
	return &u, nil
}*/

type UpdateUsuarioParams struct {
	Password string         `json:"password"`
	Image    sql.NullString `json:"image"`
	Username string         `json:"username"`
}

func UpdateUsuario(db *sql.DB, u UpdateUsuarioParams) error {
	_, err := db.Exec(
		"EXEC pa_usuario_update @userName=@p1, @password=@p2, @image=@p3",
		u.Username, u.Password, u.Image,
	)
	return err
}

/*
func UpdateUsuario(db *sql.DB, u Usuario) error {
	_, err := db.Exec("UPDATE Usuario SET password=@p1, image=@p2 WHERE userName=@p3", u.Password, u.Image, u.Username)
	return err
}*/

func UsuarioExiste(db *sql.DB, username string) (int64, error) {
	row := db.QueryRow("EXEC pa_usuario_count @userName = @p1", username)
	var count int64
	err := row.Scan(&count)
	return count, err
}

/*
func UsuarioExiste(db *sql.DB, username string) (int64, error) {
	row := db.QueryRow("SELECT COUNT(*) as count FROM Usuario WHERE userName = @p1", username)
	var count int64
	err := row.Scan(&count)
	return count, err
}*/
