extends Node

# Usuario actualmente autenticado en el juego.
# Estructura esperada: { id, username, role, created_at, last_login }
var current_user: Dictionary = {}

# ID de la run actual (partida roguelike en curso)
var current_run_id: int = -1


func _ready() -> void:
	# Aseguramos que existe al menos un admin para el modo administración.
	_ensure_default_admin()
	# Opcional: iniciar sesión automática con un usuario por defecto.
	_auto_login_default_player()


# =====================================================
# Gestión de usuarios / login
# =====================================================

func _ensure_default_admin() -> void:
	# Crea un usuario admin por defecto si no existe.
	# Esto es muy útil para tu profesor:
	# siempre podrá entrar como "admin" sin que tú tengas que tocar la BD a mano.
	var admin = DB.get_user_by_username("admin")
	if admin.is_empty():
		var ok = DB.create_user("admin", "ADMIN", "")
		if ok:
			print("[Game] Default admin user created (username: 'admin').")
		else:
			push_error("[Game] Could not create default admin user.")

func _auto_login_default_player() -> void:
	# Para desarrollo es cómodo tener un jugador por defecto
	# Así puedes arrancar el juego y ya tener user logueado.
	if current_user.is_empty():
		login_or_register("player", false)

func login_or_register(username: String, make_admin: bool = false) -> void:
	# Busca usuario en la BD, si no existe lo crea.
	var user = DB.get_user_by_username(username)

	if user.is_empty():
		var role := "ADMIN" if make_admin else "PLAYER"
		var ok = DB.create_user(username, role, "")
		if not ok:
			push_error("[Game] Error creating user: %s" % username)
			return

		user = DB.get_user_by_username(username)
		if user.is_empty():
			push_error("[Game] User creation failed (cannot reload from DB).")
			return

		print("[Game] New user created: %s (%s)" % [username, role])

	# Guardamos usuario en memoria
	current_user = user

	# Actualizamos last_login
	DB.execute("
        UPDATE users
        SET last_login = CURRENT_TIMESTAMP
        WHERE id = ?;
	", [current_user.id])

	print("[Game] Logged in as: %s (role: %s)" % [current_user.username, current_user.role])

func logout() -> void:
	current_user = {}
	current_run_id = -1
	print("[Game] User logged out.")

func is_logged_in() -> bool:
	return not current_user.is_empty()

func is_admin() -> bool:
	if not is_logged_in():
		return false
	return String(current_user.role).to_upper() == "ADMIN"


# =====================================================
# Gestión de runs (partidas roguelike)
# =====================================================

func start_run() -> void:
	if not is_logged_in():
		push_error("[Game] Cannot start run: no user logged in.")
		return

	# Insertamos nueva run vinculada al usuario
	var ok = DB.execute("
        INSERT INTO runs (user_id, start_time)
        VALUES (?, CURRENT_TIMESTAMP);
	", [current_user.id])

	if not ok:
		push_error("[Game] Error inserting new run.")
		return

	# Recuperamos el id de la última run creada
	current_run_id = DB.get_last_insert_id()
	print("[Game] Run started. ID: %d for user: %s" % [current_run_id, current_user.username])

func end_run(result: String, floor_reached: int = 0, boss_killed: String = "") -> void:
	if current_run_id <= 0:
		push_error("[Game] Cannot end run: no active run id.")
		return

	var ok = DB.execute("
        UPDATE runs
        SET end_time = CURRENT_TIMESTAMP,
            result = ?,
            floor_reached = ?,
            boss_killed = ?
        WHERE id = ?;
	", [result, floor_reached, boss_killed, current_run_id])

	if not ok:
		push_error("[Game] Error updating run end.")
	else:
		print("[Game] Run %d ended. Result: %s, Floor: %d, Boss: %s"
			% [current_run_id, result, floor_reached, boss_killed])

	current_run_id = -1

func has_active_run() -> bool:
	return current_run_id > 0


# =====================================================
# Utilidades para estadísticas / logros (hooks iniciales)
# =====================================================

func add_stat(key: String, value: String) -> void:
	if not is_logged_in():
		return

	DB.execute("
        INSERT INTO stats (user_id, key, value)
        VALUES (?, ?, ?);
	", [current_user.id, key, value])

func get_stats() -> Array:
	if not is_logged_in():
		return []
	return DB.query("
        SELECT key, value
        FROM stats
        WHERE user_id = ?;
	", [current_user.id])

func unlock_achievement(code: String) -> void:
	if not is_logged_in():
		return

	# 1) Buscar logro por código
	var rows = DB.query("
        SELECT id
        FROM achievements
        WHERE code = ?;
	", [code])

	if rows.is_empty():
		push_error("[Game] Achievement code not found: %s" % code)
		return

	var achievement_id: int = int(rows[0].id)

	# 2) Insertar en user_achievements si no existe
	DB.execute("""
        INSERT OR IGNORE INTO user_achievements (user_id, achievement_id)
        VALUES (?, ?);
	""", [current_user.id, achievement_id])
