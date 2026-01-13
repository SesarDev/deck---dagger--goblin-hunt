extends Node

var db: SQLite
var db_path := "user://deck_and_dagger_v1.db"
var is_open := false

# Plantilla opcional dentro del proyecto (solo lectura en export).
# Crea este archivo copiando tu DB actual cuando quieras “consolidar” datos:
# user://deck_and_dagger_v1.db  ->  res://data/db/deck_and_dagger_v1.db
const DB_RES_TEMPLATE := "res://data/db/deck_and_dagger_v1.db"


func _ready() -> void:
	_initialize_database()
	ensure_schema_applied()
	ensure_seed_applied()
	apply_migrations()


func _initialize_database() -> void:
	_ensure_user_db_exists()

	db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("PRAGMA foreign_keys = ON;")
	is_open = true
	print("[DB] Abierta en: ", db_path)


func _ensure_user_db_exists() -> void:
	# Si ya existe la DB en user:// no hacemos nada
	if FileAccess.file_exists(db_path):
		return

	# Si existe una plantilla en res:// la copiamos a user://
	if FileAccess.file_exists(DB_RES_TEMPLATE):
		print("[DB] No existe DB en user://. Copiando plantilla desde: ", DB_RES_TEMPLATE)

		var src := FileAccess.open(DB_RES_TEMPLATE, FileAccess.READ)
		if src == null:
			push_error("[DB] No se pudo abrir plantilla: " + DB_RES_TEMPLATE)
			return

		var dst := FileAccess.open(db_path, FileAccess.WRITE)
		if dst == null:
			src.close()
			push_error("[DB] No se pudo crear DB en: " + db_path)
			return

		dst.store_buffer(src.get_buffer(src.get_length()))
		src.close()
		dst.close()
		return

	# Si no hay plantilla, se creará vacía y luego tu pipeline aplicará schema/seed
	print("[DB] No existe DB en user:// y no hay plantilla. Se creará vacía y se aplicará schema/seed.")


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


func apply_migrations() -> void:
	# 1) Asegurar tabla de migraciones
	apply_sql_file("res://data/db/migrations/000_schema_migrations.sql")

	# 2) Lista de migraciones (ordenadas)
	var migrations := [
		"res://data/db/migrations/001_carta_desbloqueo.sql",
		"res://data/db/migrations/002_seed_unlock_rules.sql",
		"res://data/db/migrations/003_reseed_cards_and_achievements.sql",
		"res://data/db/migrations/004_add_enemy_type.sql",
		"res://data/db/migrations/005_add_enemy_imagen.sql",
	]

	for path in migrations:
		var name: String = path.get_file()

		if _migration_applied(name):
			continue

		print("[DB] Aplicando migración:", name)
		apply_sql_file(path)
		execute("INSERT OR IGNORE INTO schema_migrations(name) VALUES ('%s');" % _escape_sql(name))
		print("[DB] Migración aplicada:", name)


func _migration_applied(name: String) -> bool:
	var rows := query("SELECT name FROM schema_migrations WHERE name='%s' LIMIT 1;" % _escape_sql(name))
	return rows.size() > 0


func _escape_sql(s: String) -> String:
	return s.replace("'", "''")
