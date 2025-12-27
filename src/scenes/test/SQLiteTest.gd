extends Node

func _ready() -> void:
	print("=== SQLite test start ===")

	# 1. Crear instancia del plugin
	var db := SQLite.new()

	# 2. Configurar ruta de la base de datos
	# user:// apunta a la carpeta de datos del usuario en cada plataforma.
	db.path = "user://test_deck_and_dagger"
	db.default_extension = "db"  # añade .db si no lo pones en el nombre

	# 3. Abrir la base de datos (si no existe, la crea)
	if not db.open_db():
		push_error("Error opening DB: %s" % db.error_message)
		return

	# 4. Crear tabla de prueba si no existe
	var table_def := {
		"id": {
			"data_type": "int",
			"primary_key": true,
			"auto_increment": true
		},
		"name": {
			"data_type": "text",
			"not_null": true
		}
	}

	var ok = db.create_table("test_table", table_def)
	if not ok:
		# Si ya existe, no pasa nada, el plugin puede devolver false; no es grave para la prueba.
		print("Table might already exist or error: %s" % db.error_message)

	# 5. Insertar una fila
	var row := {
		"name": "Andres test"
	}
	ok = db.insert_row("test_table", row)
	if not ok:
		push_error("Insert error: %s" % db.error_message)

	# 6. Leer filas
	var rows = db.select_rows("test_table", "", ["id", "name"])
	print("Rows in test_table: ", rows)

	# 7. Cerrar base de datos
	db.close_db()

	print("=== SQLite test end ===")
