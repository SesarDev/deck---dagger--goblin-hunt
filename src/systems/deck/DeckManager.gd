extends Node

var deck: Array = []

func load_run_deck(run_id: int) -> void:
	deck.clear()

	if run_id < 0:
		push_error("[DeckManager] load_run_deck: run_id inválido")
		return

	var rows := Database.query("""
		SELECT rdc.id AS run_card_id, rdc.upgraded, c.*
		FROM run_deck_card rdc
		JOIN carta c ON c.id_carta = rdc.card_id
		WHERE rdc.run_id = %d;
	""" % run_id)

	for row in rows:
		deck.append(row)
