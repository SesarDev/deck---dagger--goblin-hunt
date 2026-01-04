extends RefCounted
class_name EnemyRepository

func get_all() -> Array:
	return Database.query("""
		SELECT id_enemigo, nombre, descripcion, vida_base, dano_base, recompensa_xp, disponible, tipo
		FROM enemigo
		ORDER BY id_enemigo;
	""")


func get_by_id(id_enemigo: int) -> Dictionary:
	var rows := Database.query("SELECT * FROM enemigo WHERE id_enemigo = %d;" % id_enemigo)
	return rows[0] if rows.size() > 0 else {}

func create(enemy: Dictionary) -> void:
	var sql := """
		INSERT INTO enemigo (nombre, descripcion, vida_base, dano_base, recompensa_xp, disponible)
		VALUES ('%s','%s',%d,%d,%d,%d);
	""" % [
		_escape(enemy.get("nombre", "")),
		_escape(enemy.get("descripcion", "")),
		int(enemy.get("vida_base", 10)),
		int(enemy.get("dano_base", 1)),
		int(enemy.get("recompensa_xp", 5)),
		int(enemy.get("disponible", 1))
	]
	Database.execute(sql)

func update(id_enemigo: int, enemy: Dictionary) -> void:
	var sql := """
		UPDATE enemigo SET
			nombre='%s',
			descripcion='%s',
			vida_base=%d,
			dano_base=%d,
			recompensa_xp=%d,
			disponible=%d
		WHERE id_enemigo=%d;
	""" % [
		_escape(enemy.get("nombre", "")),
		_escape(enemy.get("descripcion", "")),
		int(enemy.get("vida_base", 10)),
		int(enemy.get("dano_base", 1)),
		int(enemy.get("recompensa_xp", 5)),
		int(enemy.get("disponible", 1)),
		id_enemigo
	]
	Database.execute(sql)

func delete(id_enemigo: int) -> void:
	Database.execute("DELETE FROM enemigo WHERE id_enemigo = %d;" % id_enemigo)

func _escape(value: String) -> String:
	return value.replace("'", "''")
