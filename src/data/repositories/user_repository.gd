extends RefCounted
class_name UserRepository

func get_all() -> Array:
	return Database.query("""
		SELECT id_usuario, nombre_usuario, rol
		FROM usuario
		ORDER BY id_usuario;
	""")

func get_by_id(id_usuario: int) -> Dictionary:
	var rows := Database.query("""
		SELECT id_usuario, nombre_usuario, contrasena, rol
		FROM usuario
		WHERE id_usuario = %d
		LIMIT 1;
	""" % id_usuario)
	return rows[0] if rows.size() > 0 else {}

func create(user: Dictionary) -> void:
	var sql := """
		INSERT INTO usuario (nombre_usuario, contrasena, rol)
		VALUES ('%s','%s','%s');
	""" % [
		_escape(String(user.get("nombre_usuario", ""))),
		_escape(String(user.get("contrasena", ""))),
		_escape(String(user.get("rol", "PLAYER"))).to_upper()
	]
	Database.execute(sql)

	# Asegurar progreso del usuario recién creado
	var rows := Database.query("""
		SELECT id_usuario
		FROM usuario
		WHERE nombre_usuario='%s'
		LIMIT 1;
	""" % _escape(String(user.get("nombre_usuario", ""))))

	if rows.size() > 0:
		var uid := int(rows[0].get("id_usuario", -1))
		if uid > 0:
			Database.execute("""
				INSERT OR IGNORE INTO progreso_usuario
				(id_usuario, nivel, experiencia, fecha_ultima_partida, victorias, derrotas, run_id_activa)
				VALUES (%d, 1, 0, NULL, 0, 0, NULL);
			""" % uid)

func update(id_usuario: int, user: Dictionary) -> void:
	Database.execute("""
		UPDATE usuario SET
			nombre_usuario='%s',
			contrasena='%s',
			rol='%s'
		WHERE id_usuario=%d;
	""" % [
		_escape(String(user.get("nombre_usuario", ""))),
		_escape(String(user.get("contrasena", ""))),
		_escape(String(user.get("rol", "PLAYER"))).to_upper(),
		id_usuario
	])

func delete(id_usuario: int) -> void:
	if id_usuario == 1:
		return
	Database.execute("DELETE FROM usuario WHERE id_usuario=%d;" % id_usuario)

func exists_username(nombre_usuario: String, exclude_id: int = -1) -> bool:
	nombre_usuario = nombre_usuario.strip_edges()
	if nombre_usuario.is_empty():
		return false

	var sql := "SELECT 1 AS ok FROM usuario WHERE nombre_usuario='%s'" % _escape(nombre_usuario)
	if exclude_id != -1:
		sql += " AND id_usuario != %d" % exclude_id
	sql += " LIMIT 1;"

	return Database.query(sql).size() > 0


# =========================
# PERFIL (JOIN con progreso_usuario)
# =========================

func get_profile_summary(id_usuario: int) -> Dictionary:
	var rows := Database.query("""
		SELECT
			u.id_usuario,
			u.nombre_usuario,
			u.rol,
			COALESCE(p.victorias, 0) AS victorias,
			COALESCE(p.derrotas, 0) AS derrotas,
			COALESCE(p.run_id_activa, -1) AS run_id_activa
		FROM usuario u
		LEFT JOIN progreso_usuario p ON p.id_usuario = u.id_usuario
		WHERE u.id_usuario = %d
		LIMIT 1;
	""" % id_usuario)

	return rows[0] if rows.size() > 0 else {}

func get_run_label(run_id: int) -> String:
	if run_id <= 0:
		return "—"
	var rows := Database.query("SELECT floor FROM run WHERE id=%d LIMIT 1;" % run_id)
	if rows.is_empty():
		return "—"
	return "Piso %d" % int(rows[0].get("floor", 1))


func _escape(value: String) -> String:
	return value.replace("'", "''")
