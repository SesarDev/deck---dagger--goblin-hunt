extends Node
class_name DBManager

const DB_PATH := "user://deck_and_dagger"

var db: SQLite

func _ready() -> void:
	_connect()
	_init_schema()

func _connect() -> void:
	db = SQLite.new()
	db.path = DB_PATH
	db.default_extension = "db"
	db.foreign_keys = true
	db.verbosity_level = 1

	var ok := db.open_db()
	if not ok:
		push_error("DB ERROR opening: %s" % db.error_message)
	else:
		print("[DB] Opened at: ", DB_PATH, ".db")

func _init_schema() -> void:
	# 1) Users
	_exec("""
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT,
        role TEXT NOT NULL DEFAULT 'PLAYER',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        last_login TEXT
    );
	""")

	# 2) Runs
	_exec("""
    CREATE TABLE IF NOT EXISTS runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        start_time TEXT DEFAULT CURRENT_TIMESTAMP,
        end_time TEXT,
        result TEXT,
        floor_reached INTEGER DEFAULT 0,
        boss_killed TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
	""")

	# 3) Stats
	_exec("""
    CREATE TABLE IF NOT EXISTS stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
	""")

	# 4) Achievements (definición)
	_exec("""
    CREATE TABLE IF NOT EXISTS achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT NOT NULL
    );
	""")

	# 5) User achievements
	_exec("""
    CREATE TABLE IF NOT EXISTS user_achievements (
        user_id INTEGER NOT NULL,
        achievement_id INTEGER NOT NULL,
        unlocked_at TEXT DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, achievement_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (achievement_id) REFERENCES achievements(id) ON DELETE CASCADE
    );
	""")

	# 6) Cards
	_exec("""
    CREATE TABLE IF NOT EXISTS cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        cost INTEGER NOT NULL,
        type TEXT NOT NULL,
        target TEXT NOT NULL,
        rarity TEXT NOT NULL,
        base_damage INTEGER,
        base_block INTEGER,
        effect_data TEXT
    );
	""")

	# 7) Enemies
	_exec("""
    CREATE TABLE IF NOT EXISTS enemies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        max_hp INTEGER NOT NULL,
        behavior_data TEXT
    );
	""")

	# 8) Bosses
	_exec("""
    CREATE TABLE IF NOT EXISTS bosses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        max_hp INTEGER NOT NULL,
        behavior_data TEXT
    );
	""")

	# 9) Events
	_exec("""
    CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        options_data TEXT
    );
	""")

	print("[DB] Schema initialized.")

# =====================================================
# Internals: ejecutar SQL simple (CREATE, INSERT, etc.)
# =====================================================

func _exec(sql: String, params: Array = []) -> bool:
	var ok: bool
	if params.is_empty():
		ok = db.query(sql)
	else:
		ok = db.query_with_bindings(sql, params)

	if not ok:
		push_error("DB EXEC ERROR: %s | SQL: %s" % [db.error_message, sql])
	return ok

# =====================================================
# Helpers genéricos
# =====================================================

func query(sql: String, params: Array = []) -> Array:
	var ok: bool
	if params.is_empty():
		ok = db.query(sql)
	else:
		ok = db.query_with_bindings(sql, params)

	if not ok:
		push_error("DB QUERY ERROR: %s | SQL: %s" % [db.error_message, sql])
		return []

	return db.query_result

func execute(sql: String, params: Array = []) -> bool:
	var ok: bool
	if params.is_empty():
		ok = db.query(sql)
	else:
		ok = db.query_with_bindings(sql, params)

	if not ok:
		push_error("DB EXEC ERROR: %s | SQL: %s" % [db.error_message, sql])
		return false

	return true

func get_last_insert_id() -> int:
	return db.last_insert_rowid

# =====================================================
# CRUD específico: Users (para el modo admin)
# =====================================================

func create_user(username: String, role: String = "PLAYER", password_hash: String = "") -> bool:
	return execute("
        INSERT INTO users (username, role, password_hash)
        VALUES (?, ?, ?);
	", [username, role, password_hash])

func get_all_users() -> Array:
	return query("
        SELECT id, username, role, created_at, last_login
        FROM users
        ORDER BY id;
	")

func get_user_by_username(username: String) -> Dictionary:
	var rows = query("
        SELECT *
        FROM users
        WHERE username = ?
        LIMIT 1;
	", [username])

	return rows[0] if rows.size() > 0 else {}

func update_user_role(user_id: int, new_role: String) -> bool:
	return execute("
        UPDATE users
        SET role = ?
        WHERE id = ?;
	", [new_role, user_id])

func delete_user(user_id: int) -> bool:
	return execute("
        DELETE FROM users
        WHERE id = ?;
	", [user_id])
