extends RefCounted
class_name AchievementService

var progression := ProgressionService.new()

func grant_by_condition(user_id: int, condition: String) -> bool:
	# ¿Ya obtenido?
	var already := Database.query("""
		SELECT ul.obtenido
		FROM usuario_logro ul
		JOIN logro l ON l.id_logro = ul.id_logro
		WHERE ul.id_usuario = %d AND l.condicion = '%s'
		LIMIT 1;
	""" % [user_id, _escape_sql(condition)])

	if not already.is_empty() and int(already[0]["obtenido"]) == 1:
		return false

	# Marcar como obtenido
	Database.execute("""
		UPDATE usuario_logro
		SET obtenido = 1, fecha_obtencion = datetime('now')
		WHERE id_usuario = %d
		  AND id_logro = (SELECT id_logro FROM logro WHERE condicion = '%s' LIMIT 1);
	""" % [user_id, _escape_sql(condition)])

	# Desbloquear cartas por logro
	progression.apply_achievement_unlocks(user_id)
	return true

func on_combat_ended(user_id: int, victory: bool, enemy_tipo: String, damage_taken_in_battle: int) -> Array[String]:
	var unlocked: Array[String] = []

	if victory:
		# Intocable
		if damage_taken_in_battle == 0:
			if grant_by_condition(user_id, "NO_HIT_BATTLE"):
				unlocked.append("Intocable")

		# Boss 1
		if enemy_tipo == "BOSS_1":
			if grant_by_condition(user_id, "KILL_BOSS_1"):
				unlocked.append("Cabeza de Cartel")

	return unlocked

func _escape_sql(s: String) -> String:
	return s.replace("'", "''")
