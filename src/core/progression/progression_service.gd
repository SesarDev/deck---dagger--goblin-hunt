extends RefCounted
class_name ProgressionService

func ensure_user_card_rows(user_id: int) -> void:
	Database.execute("""
		INSERT OR IGNORE INTO usuario_carta(id_usuario, id_carta, desbloqueada)
		SELECT %d, c.id_carta, 0
		FROM carta c
		WHERE c.disponible = 1;
	""" % user_id)

func apply_base_unlocks(user_id: int) -> void:
	Database.execute("""
		UPDATE usuario_carta
		SET desbloqueada = 1
		WHERE id_usuario = %d
		  AND id_carta IN (SELECT id_carta FROM carta_desbloqueo WHERE tipo='BASE');
	""" % user_id)

func apply_level_unlocks(user_id: int, level: int) -> void:
	Database.execute("""
		UPDATE usuario_carta
		SET desbloqueada = 1
		WHERE id_usuario = %d
		  AND id_carta IN (
			  SELECT id_carta FROM carta_desbloqueo
			  WHERE tipo='NIVEL' AND valor <= %d
		  );
	""" % [user_id, level])

func apply_achievement_unlocks(user_id: int) -> void:
	Database.execute("""
		UPDATE usuario_carta
		SET desbloqueada = 1
		WHERE id_usuario = %d
		  AND id_carta IN (
			  SELECT cd.id_carta
			  FROM carta_desbloqueo cd
			  JOIN usuario_logro ul ON ul.id_logro = cd.valor
			  WHERE cd.tipo='LOGRO'
			    AND ul.id_usuario = %d
			    AND ul.obtenido = 1
		  );
	""" % [user_id, user_id])

func refresh_all_unlocks(user_id: int) -> void:
	ensure_user_card_rows(user_id)
	apply_base_unlocks(user_id)

	var rows := Database.query("SELECT nivel FROM progreso_usuario WHERE id_usuario=%d;" % user_id)
	var level: int = 1
	if not rows.is_empty():
		level = int(rows[0]["nivel"])

	apply_level_unlocks(user_id, level)
	apply_achievement_unlocks(user_id)
