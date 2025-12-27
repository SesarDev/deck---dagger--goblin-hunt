extends Node

var db: SQLite
var db_path := "user://deck_and_dagger_v1.db"
var is_open := false

func _ready() -> void:
	initialize_database()
	ensure_schema_applied()
	ensure_seed_applied()

func initialize_database() -> void:
	db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("PRAGMA foreign_keys = ON;")
	is_open = true
	print("[DB] Abierta en: ", db_path)

func ensure_schema_applied() -> void:
	# Si ya existe la tabla 'usuario', asumimos schema aplicado
	var rows := query("SELECT name FROM sqlite_master WHERE type='table' AND name='usuario';")
	if rows.size() > 0:
		print("[DB] Schema ya aplicado.")
		return

	print("[DB] Aplicando schema.sql...")
	apply_sql_file("res://data/db/schema.sql")
	print("[DB] Schema aplicado.")

func ensure_seed_applied() -> void:
	# Si ya hay cartas, asumimos seed aplicado
	var rows := query("SELECT COUNT(*) AS n FROM carta;")
	if rows.size() > 0 and int(rows[0].get("n", 0)) > 0:
		print("[DB] Seed ya aplicado.")
		return

	print("[DB] Aplicando seed.sql...")
	apply_sql_file("res://data/db/seed.sql")
	print("[DB] Seed aplicado.")

func apply_sql_file(file_path: String) -> void:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		push_error("[DB] No se pudo abrir: " + file_path)
		return

	var sql_text := f.get_as_text()
	f.close()

	# Divide por ';' (suficiente para nuestro schema)
	var statements := sql_text.split(";", false)
	for s in statements:
		var stmt := s.strip_edges()
		if stmt.is_empty():
			continue
		execute(stmt + ";")

func execute(sql: String) -> void:
	if not is_open:
		push_error("[DB] execute(): BD no abierta")
		return
	db.query(sql)

func query(sql: String) -> Array:
	if not is_open:
		push_error("[DB] query(): BD no abierta")
		return []
	db.query(sql)
	return db.query_result

func close() -> void:
	if is_open:
		db.close_db()
		is_open = false
