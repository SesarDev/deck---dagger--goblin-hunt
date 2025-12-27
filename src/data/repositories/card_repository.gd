extends RefCounted
class_name CardRepository

func get_all() -> Array:
	return Database.query("""
		SELECT id_carta, nombre, descripcion, tipo, coste_energia, valor_base, rareza, disponible
		FROM carta
		ORDER BY id_carta;
	""")

func get_by_id(id_carta: int) -> Dictionary:
	var rows := Database.query("SELECT * FROM carta WHERE id_carta = %d;" % id_carta)
	return rows[0] if rows.size() > 0 else {}

func create(card: Dictionary) -> void:
	var sql := """
		INSERT INTO carta (nombre, descripcion, tipo, coste_energia, valor_base, rareza, disponible)
		VALUES ('%s','%s','%s',%d,%d,'%s',%d);
	""" % [
		_escape(card.get("nombre", "")),
		_escape(card.get("descripcion", "")),
		_escape(card.get("tipo", "ATAQUE")),
		int(card.get("coste_energia", 1)),
		int(card.get("valor_base", 0)),
		_escape(card.get("rareza", "COMUN")),
		int(card.get("disponible", 1))
	]
	Database.execute(sql)

func update(id_carta: int, card: Dictionary) -> void:
	var sql := """
		UPDATE carta SET
			nombre='%s',
			descripcion='%s',
			tipo='%s',
			coste_energia=%d,
			valor_base=%d,
			rareza='%s',
			disponible=%d
		WHERE id_carta=%d;
	""" % [
		_escape(card.get("nombre", "")),
		_escape(card.get("descripcion", "")),
		_escape(card.get("tipo", "ATAQUE")),
		int(card.get("coste_energia", 1)),
		int(card.get("valor_base", 0)),
		_escape(card.get("rareza", "COMUN")),
		int(card.get("disponible", 1)),
		id_carta
	]
	Database.execute(sql)

func delete(id_carta: int) -> void:
	Database.execute("DELETE FROM carta WHERE id_carta = %d;" % id_carta)

func _escape(value: String) -> String:
	# Escape básico para comillas simples en SQL
	return value.replace("'", "''")
