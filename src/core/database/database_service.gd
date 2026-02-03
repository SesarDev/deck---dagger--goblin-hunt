extends Node

var db: SQLite
var db_path := "user://deck_and_dagger_v1.db"
var is_open := false

const DB_RES_TEMPLATE := "res://data/db/deck_and_dagger_v1.db"


func _ready() -> void:
	_initialize_database()
	ensure_schema_applied()
	ensure_seed_applied()

	# ✅ Asegurar columnas nuevas y filas de progreso
	ensure_profile_stats_columns()
	ensure_progress_rows_for_all_users()

	apply_migrations()
	ensure_starter_deck_seeded()


func _initialize_database() -> void:
	_ensure_user_db_exists()

	db = SQLite.new()
	db.path = db_path
	db.open_db()
	db.query("PRAGMA foreign_keys = ON;")
	is_open = true
	print("[DB] Abierta en: ", db_path)


func _ensure_user_db_exists() -> void:
	if FileAccess.file_exists(db_path):
		return

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

	print("[DB] No existe DB en user:// y no hay plantilla. Se creará vacía y se aplicará schema/seed.")


func ensure_schema_applied() -> void:
	var rows := query("SELECT name FROM sqlite_master WHERE type='table' AND name='usuario';")
	if rows.size() > 0:
		print("[DB] Schema ya aplicado.")
		return

	print("[DB] Aplicando schema.sql...")
	apply_sql_file("res://data/db/schema.sql")
	print("[DB] Schema aplicado.")


func ensure_seed_applied() -> void:
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
	if db.error_message != "" and db.error_message != "not an error":
		print("[DB][ERR] ", db.error_message, " | SQL: ", sql)


func query(sql: String) -> Array:
	if not is_open:
		push_error("[DB] query(): BD no abierta")
		return []
	db.query(sql)
	if db.error_message != "" and db.error_message != "not an error":
		print("[DB][ERR] ", db.error_message, " | SQL: ", sql)
	return db.query_result


func close() -> void:
	if is_open:
		db.close_db()
		is_open = false


func apply_migrations() -> void:
	apply_sql_file("res://data/db/migrations/000_schema_migrations.sql")

	var migrations := [
		# aquí tus migraciones si las reactivas
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


# =====================================================
#  RUNS Y MAZO DE LA RUN
# =====================================================

func create_run() -> int:
	var seed := randi()
	execute("""
		INSERT INTO run (seed, floor, gold, hp, max_hp)
		VALUES (%d, 1, 50, 100, 100);
	""" % seed)

	var new_run_id := get_last_insert_id()
	print("[RUN] new_run_id:", new_run_id)

	if new_run_id <= 0:
		push_error("[RUN] create_run(): no se pudo obtener run_id")
		return -1

	_populate_starter_deck(new_run_id)

	print("[RUN] run_deck_card count:",
		query("SELECT COUNT(*) AS n FROM run_deck_card WHERE run_id=%d;" % new_run_id)
	)

	return new_run_id


func _populate_starter_deck(run_id: int) -> void:
	var already: Array = query("SELECT COUNT(*) AS n FROM run_deck_card WHERE run_id=%d;" % run_id)
	if already.size() > 0 and int(already[0].get("n", 0)) > 0:
		print("[RUN] run_deck_card ya poblado para run_id=", run_id, " -> skip")
		return

	var rows: Array = query("SELECT card_id, copies FROM starter_deck;")
	for row in rows:
		var card_id: int = int((row as Dictionary).get("card_id", 0))
		var copies: int = int((row as Dictionary).get("copies", 0))
		for _i in range(copies):
			execute("INSERT INTO run_deck_card (run_id, card_id) VALUES (%d, %d);" % [run_id, card_id])


func ensure_starter_deck_seeded() -> void:
	var rows := query("SELECT COUNT(*) AS n FROM starter_deck;")
	if rows.size() > 0 and int(rows[0].get("n", 0)) > 0:
		return

	execute("DELETE FROM starter_deck;")
	execute("INSERT INTO starter_deck(card_id, copies) VALUES (1, 5);")
	execute("INSERT INTO starter_deck(card_id, copies) VALUES (4, 4);")
	execute("INSERT INTO starter_deck(card_id, copies) VALUES (6, 1);")
	print("[DB] starter_deck sembrado por código.")


# =====================================================
#  PERFIL: columnas + filas de progreso
# =====================================================

func ensure_profile_stats_columns() -> void:
	_ensure_column("progreso_usuario", "victorias", "INTEGER NOT NULL DEFAULT 0")
	_ensure_column("progreso_usuario", "derrotas", "INTEGER NOT NULL DEFAULT 0")
	_ensure_column("progreso_usuario", "run_id_activa", "INTEGER")


func _ensure_column(table_name: String, column_name: String, column_def: String) -> void:
	var cols := query("PRAGMA table_info(%s);" % table_name)
	for c in cols:
		if String((c as Dictionary).get("name", "")) == column_name:
			return
	print("[DB] Añadiendo columna %s.%s..." % [table_name, column_name])
	execute("ALTER TABLE %s ADD COLUMN %s %s;" % [table_name, column_name, column_def])


func ensure_progress_rows_for_all_users() -> void:
	execute("""
		INSERT OR IGNORE INTO progreso_usuario
		(id_usuario, nivel, experiencia, fecha_ultima_partida, victorias, derrotas, run_id_activa)
		SELECT id_usuario, 1, 0, NULL, 0, 0, NULL
		FROM usuario;
	""")


# =====================================================
#  STATS API (para que el perfil pueda mostrarlos)
# =====================================================

func add_win(user_id: int) -> void:
	if user_id <= 0: return
	execute("""
		UPDATE progreso_usuario
		SET victorias = COALESCE(victorias,0) + 1,
		    fecha_ultima_partida = CURRENT_TIMESTAMP
		WHERE id_usuario = %d;
	""" % user_id)

func add_loss(user_id: int) -> void:
	if user_id <= 0: return
	execute("""
		UPDATE progreso_usuario
		SET derrotas = COALESCE(derrotas,0) + 1,
		    fecha_ultima_partida = CURRENT_TIMESTAMP
		WHERE id_usuario = %d;
	""" % user_id)

func set_active_run_for_user(user_id: int, run_id: int) -> void:
	if user_id <= 0: return
	execute("""
		UPDATE progreso_usuario
		SET run_id_activa = %d,
		    fecha_ultima_partida = CURRENT_TIMESTAMP
		WHERE id_usuario = %d;
	""" % [run_id, user_id])


# =====================================================
#  UTILIDADES
# =====================================================

func get_last_insert_id() -> int:
	var rows := query("SELECT last_insert_rowid() AS id;")
	if rows.size() > 0:
		return int(rows[0]["id"])
	return -1

func _escape_sql(s: String) -> String:
	return s.replace("'", "''")
