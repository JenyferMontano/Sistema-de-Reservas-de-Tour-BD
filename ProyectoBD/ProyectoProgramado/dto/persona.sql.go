package dto

import (
	"database/sql"
)

// Aquí va la lógica de acceso a datos para Persona

func GetAllPersonas(db *sql.DB) ([]Persona, error) {
	rows, err := db.Query("EXEC pa_persona_getall")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var personas []Persona
	for rows.Next() {
		var p Persona
		err := rows.Scan(&p.IdPersona, &p.Nombre, &p.Apellido1, &p.Apellido2, &p.FechaNac, &p.Direccion, &p.Telefono, &p.Correo)
		if err != nil {
			return nil, err
		}
		personas = append(personas, p)
	}
	return personas, nil
}

func GetPersonaById(db *sql.DB, id int32) (*Persona, error) {
	row := db.QueryRow("EXEC pa_persona_getbyid @idpersona = @p1", id)

	var p Persona
	err := row.Scan(&p.IdPersona, &p.Nombre, &p.Apellido1, &p.Apellido2, &p.FechaNac, &p.Direccion, &p.Telefono, &p.Correo)
	if err != nil {
		return nil, err
	}
	return &p, nil
}



func CreatePersona(db *sql.DB, p Persona) error {
    _, err := db.Exec(
        "EXEC pa_persona_insert @idpersona=@p1, @nombre=@p2, @apellido_1=@p3, @apellido_2=@p4, @fechanacstr=@p5, @direccion=@p6, @telefono=@p7, @correo=@p8",
        p.IdPersona, p.Nombre, p.Apellido1, p.Apellido2, p.FechaNac.Format("02/01/2006"), p.Direccion, p.Telefono, p.Correo,
    )
    return err
}



func UpdatePersona(db *sql.DB, p Persona) error {
	fechaStr := p.FechaNac.Format("02/01/2006")
	_, err := db.Exec(
		"EXEC pa_persona_update @idpersona=@p1, @nombre=@p2, @apellido_1=@p3, @apellido_2=@p4, @fechanacstr=@p5, @direccion=@p6, @telefono=@p7, @correo=@p8",
		p.IdPersona, p.Nombre, p.Apellido1, p.Apellido2, fechaStr, p.Direccion, p.Telefono, p.Correo,
	)
	return err
}



func DeletePersona(db *sql.DB, id int32) error {
	_, err := db.Exec("EXEC pa_PersonaDelete @idpersona = @p1", id)
	return err
}


