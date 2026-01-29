extends RefCounted
class_name CombatManager

signal state_changed
signal combat_ended(victory: bool, xp_gained: int, enemy_name: String)

var enemy_repo := EnemyRepository.new()

var player := PlayerCombatState.new()
var enemy := EnemyCombatState.new()

var achievement_service := AchievementService.new()
var _player_hp_at_start: int = 0


func start_combat(enemy_id: int = -1) -> void:
	# Reset del estado del combate (siempre debe empezar limpio)
	player.deck.clear()
	player.hand.clear()
	player.discard.clear()
	
	# -----------------------------
	# 1) Cargar enemigo
	# -----------------------------
	var enemy_row: Dictionary
	_player_hp_at_start = player.hp

	if enemy_id != -1:
		enemy_row = enemy_repo.get_by_id(enemy_id)
	else:
		enemy_row = _pick_enemy_row_for_current_node()

	enemy.load_from_row(enemy_row)

	# -----------------------------
	# 2) Cargar MAZO DE LA RUN (SIN JOIN duplicable)
	# -----------------------------
	var run_id: int = GameState.run_id
	if run_id <= 0:
		push_error("CombatManager: run_id inválido (%d)" % run_id)
		return
	print("[COMBAT] count run_deck_card =", Database.query("SELECT COUNT(*) AS n FROM run_deck_card WHERE run_id=%d;" % run_id))

	# 2.1) Traer IDs del mazo de la run
	var id_rows: Array = Database.query("""
		SELECT card_id
		FROM run_deck_card
		WHERE run_id = %d
		ORDER BY id;
	""" % run_id)

	print("[COMBAT] run_deck_card rows =", id_rows.size())

	# 2.2) Traer 1 carta por id_carta (evita duplicaciones por JOIN)
	for row in id_rows:
		var card_id: int = int((row as Dictionary).get("card_id", 0))
		if card_id <= 0:
			continue

		var crows: Array = Database.query("SELECT * FROM carta WHERE id_carta = %d LIMIT 1;" % card_id)
		if not crows.is_empty():
			player.deck.append(crows[0])

	if player.deck.is_empty():
		push_error("CombatManager: el mazo de la run está vacío (run_id=%d)" % run_id)
		return

	print("[COMBAT] run_id =", run_id)
	print("[COMBAT] deck_size =", player.deck.size())
	print("[COMBAT] primera carta =", player.deck[0].get("nombre", "?"))

	_shuffle(player.deck)

	# -----------------------------
	# 3) Primer turno
	# -----------------------------
	start_player_turn()
	state_changed.emit()

	

# ==================================================
# ENEMIGOS SEGÚN NODO DEL MAPA
# ==================================================
func _pick_enemy_row_for_current_node() -> Dictionary:
	var node_id: String = String(GameState.current_node_id)
	var node_type: int = MapNode.NodeType.NORMAL

	if GameState.node_types.has(node_id):
		node_type = int(GameState.node_types[node_id])

	if node_type == MapNode.NodeType.BOSS:
		if GameState.boss_enemy_id > 0:
			var row := enemy_repo.get_by_id(GameState.boss_enemy_id)
			if not row.is_empty():
				return row
		return _pick_random_enemy_by_tipo("Jefe")

	if node_type == MapNode.NodeType.ELITE:
		return _pick_random_enemy_by_tipo("Élite")

	return _pick_random_enemy_by_tipo("Normal")


func _pick_random_enemy_by_tipo(tipo: String) -> Dictionary:
	var enemies := enemy_repo.get_all()
	if enemies.is_empty():
		return {}

	var filtered := []
	for e in enemies:
		if typeof(e) == TYPE_DICTIONARY and String(e.get("tipo", "")) == tipo:
			filtered.append(e)

	if filtered.is_empty():
		return enemies.pick_random()

	return filtered.pick_random()


# ==================================================
# TURNOS
# ==================================================
func start_player_turn() -> void:
	player.reset_for_new_turn()
	_draw_cards(player.draw_per_turn)
	state_changed.emit()


func play_card(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= player.hand.size():
		return

	var c := player.hand[hand_index]
	var cost := int(c["coste_energia"])

	if player.energy < cost:
		return

	player.energy -= cost
	_apply_card_effect(c)

	var played : Dictionary = player.hand.pop_at(hand_index)
	player.discard.append(played)

	_check_end_conditions()
	state_changed.emit()


func end_player_turn() -> void:
	while player.hand.size() > 0:
		player.discard.append(player.hand.pop_back())

	_enemy_act()
	_check_end_conditions()

	if player.hp > 0 and enemy.hp > 0:
		start_player_turn()


# ==================================================
# LÓGICA ENEMIGA
# ==================================================
func _enemy_act() -> void:
	var dmg := enemy.damage

	var absorbed := mini(player.block, dmg)
	player.block -= absorbed
	dmg -= absorbed

	player.hp = maxi(0, player.hp - dmg)


# ==================================================
# EFECTOS DE CARTAS
# ==================================================
func _apply_card_effect(c: Dictionary) -> void:
	var tipo := String(c["tipo"])
	var value := int(c["valor_base"])

	match tipo:
		"ATAQUE":
			enemy.hp = maxi(0, enemy.hp - value)
		"DEFENSA":
			player.block += value
		"HABILIDAD":
			if String(c["nombre"]) == "Concentración":
				player.energy += 1
			else:
				player.hp = mini(player.max_hp, player.hp + value)


# ==================================================
# ROBO Y BARAJADO
# ==================================================
func _draw_cards(n: int) -> void:
	for _i in range(n):
		if player.deck.is_empty():
			if player.discard.is_empty():
				return
			player.deck = player.discard.duplicate(true)
			player.discard.clear()
			_shuffle(player.deck)

		player.hand.append(player.deck.pop_back())


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# ==================================================
# FIN DE COMBATE
# ==================================================
func _check_end_conditions() -> void:
	if enemy.hp <= 0:
		_on_victory()
		var damage_taken := maxi(0, _player_hp_at_start - player.hp)
		achievement_service.on_combat_ended(1, true, enemy.tipo, damage_taken)
		combat_ended.emit(true, enemy.recompensa_xp, enemy.name)
	elif player.hp <= 0:
		combat_ended.emit(false, 0, enemy.name)


func _on_victory() -> void:
	var user_id := 1
	var xp_gained := enemy.recompensa_xp

	Database.execute("""
		UPDATE progreso_usuario
		SET experiencia = experiencia + %d,
		    fecha_ultima_partida = datetime('now')
		WHERE id_usuario = %d;
	""" % [xp_gained, user_id])

	_check_level_up(user_id)


func _check_level_up(user_id: int) -> void:
	var rows := Database.query("""
		SELECT nivel, experiencia
		FROM progreso_usuario
		WHERE id_usuario = %d;
	""" % user_id)

	if rows.is_empty():
		return

	var nivel := int(rows[0]["nivel"])
	var xp := int(rows[0]["experiencia"])

	var new_level := int(xp / 100) + 1
	if new_level > nivel:
		Database.execute("""
			UPDATE progreso_usuario
			SET nivel = %d
			WHERE id_usuario = %d;
		""" % [new_level, user_id])

		ProgressionService.new().apply_level_unlocks(user_id, new_level)
