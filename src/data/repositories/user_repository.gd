extends RefCounted
class_name UserRepository

func get_all() -> Array:
	return Database.query("""
		SELECT id_usuario, nombre_usuario, contrasena, rol
		FROM usuario
		ORDER BY id_usuario;
	""")

func get_by_id(id_usuario: int) -> Dictionary:
	var rows := Database.query("SELECT * FROM usuario WHERE id_usuario = %d;" % id_usuario)
	return rows[0] if rows.size() > 0 else {}

func create(user: Dictionary) -> void:
	var sql := """
		INSERT INTO usuario (nombre_usuario, contrasena, rol)
		VALUES ('%s','%s','%s');
	""" % [
		_escape(user.get("nombre_usuario", "")),
		_escape(user.get("contrasena", "")),
		_escape(user.get("rol", "PLAYER")).to_upper()
	]
	Database.execute(sql)

	# Asegura fila de progreso (evita errores posteriores por UNIQUE/FK)
	var rows := Database.query(
		"SELECT id_usuario AS id FROM usuario WHERE nombre_usuario='%s' LIMIT 1;" %
		_escape(user.get("nombre_usuario", ""))
	)
	if rows.size() > 0:
		var uid := int(rows[0].get("id", -1))
		if uid > 0:
			Database.execute("""
				INSERT OR IGNORE INTO progreso_usuario (id_usuario, nivel, experiencia, fecha_ultima_partida)
				VALUES (%d, 1, 0, NULL);
			""" % uid)

func update(id_usuario: int, user: Dictionary) -> void:
	var sql := """
		UPDATE usuario SET
			nombre_usuario='%s',
			contrasena='%s',
			rol='%s'
		WHERE id_usuario=%d;
	""" % [
		_escape(user.get("nombre_usuario", "")),
		_escape(user.get("contrasena", "")),
		_escape(user.get("rol", "PLAYER")).to_upper(),
		id_usuario
	]
	Database.execute(sql)

func delete(id_usuario: int) -> void:
	# Protección: no borrar admin por defecto
	if id_usuario == 1:
		return
	Database.execute("DELETE FROM usuario WHERE id_usuario = %d;" % id_usuario)

func exists_username(nombre_usuario: String, exclude_id: int = -1) -> bool:
	nombre_usuario = nombre_usuario.strip_edges()
	if nombre_usuario.is_empty():
		return false

	var sql := "SELECT 1 AS ok FROM usuario WHERE nombre_usuario='%s'" % _escape(nombre_usuario)
	if exclude_id != -1:
		sql += " AND id_usuario != %d" % exclude_id
	sql += " LIMIT 1;"

	var rows := Database.query(sql)
	return rows.size() > 0

func _escape(value: String) -> String:
	return value.replace("'", "''")
