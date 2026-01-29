extends RefCounted
class_name RewardService

func get_combat_reward_choices(user_id: int, amount: int = 3) -> Array:
	var rows: Array = Database.query("""
		SELECT c.*
		FROM usuario_carta uc
		JOIN carta c ON c.id_carta = uc.id_carta
		WHERE uc.id_usuario = %d
		  AND uc.desbloqueada = 1
		  AND c.disponible = 1
		  AND c.id_carta NOT IN (SELECT card_id FROM starter_deck)
		ORDER BY RANDOM()
		LIMIT %d;
	""" % [user_id, amount])

	return rows

func add_card_to_run(run_id: int, card_id: int) -> void:
	Database.execute("""
		INSERT INTO run_deck_card (run_id, card_id)
		VALUES (%d, %d);
	""" % [run_id, card_id])

func add_gold_to_run(run_id: int, gold: int) -> void:
	Database.execute("""
		UPDATE run
		SET gold = gold + %d
		WHERE id = %d;
	""" % [gold, run_id])
