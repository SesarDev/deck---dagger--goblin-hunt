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
	# 1) Cargar enemigo desde BD
	var enemy_row: Dictionary

	_player_hp_at_start = player.hp

	if enemy_id != -1:
		# Override explícito (útil para testing o combates concretos)
		enemy_row = enemy_repo.get_by_id(enemy_id)
	else:
		# Selección automática según tipo de nodo del mapa
		enemy_row = _pick_enemy_row_for_current_node()

	enemy.load_from_row(enemy_row)

	# 2) Preparar mazo inicial desde usuario_carta (MVP: usuario 1 = admin)
	player.deck.clear()

	var user_id: int = 1 # TODO: reemplazar por perfil activo
	var rows := Database.query("""
		SELECT c.*
		FROM usuario_carta uc
		JOIN carta c ON c.id_carta = uc.id_carta
		WHERE uc.id_usuario = %d AND uc.desbloqueada = 1 AND c.disponible = 1
		ORDER BY c.id_carta;
	""" % user_id)

	for r in rows:
		player.deck.append(r)

	# Fallback por si el usuario no tiene cartas desbloqueadas
	if player.deck.is_empty():
		rows = Database.query("SELECT * FROM carta WHERE disponible = 1 ORDER BY id_carta LIMIT 5;")
		for r2 in rows:
			player.deck.append(r2)

	_shuffle(player.deck)
	player.hand.clear()
	player.discard.clear()

	# 3) Primer turno
	start_player_turn()
	state_changed.emit()


func _pick_enemy_row_for_current_node() -> Dictionary:
	# Determina el tipo del nodo actual en el mapa y elige un enemigo acorde.
	# Para BOSS, usa GameState.boss_enemy_id (ya existe en GameState.gd).

	var node_id: String = String(GameState.current_node_id)

	var node_type: int = MapNode.NodeType.NORMAL
	if GameState.node_types.has(node_id):
		node_type = int(GameState.node_types.get(node_id, MapNode.NodeType.NORMAL))

	# 1) BOSS: cargar el jefe asignado a la run si existe
	if node_type == MapNode.NodeType.BOSS:
		var boss_id: int = int(GameState.boss_enemy_id)

		if boss_id > 0:
			var row: Dictionary = enemy_repo.get_by_id(boss_id)
			if not row.is_empty():
				return row

		# Fallback: random Jefe si no hay asignado / no existe en BD
		return _pick_random_enemy_by_tipo("Jefe")

	# 2) ÉLITE
	if node_type == MapNode.NodeType.ELITE:
		return _pick_random_enemy_by_tipo("Élite")

	# 3) NORMAL (y por defecto)
	return _pick_random_enemy_by_tipo("Normal")



func _pick_random_enemy_by_tipo(tipo: String) -> Dictionary:
	# EnemyRepository.get_all() ya lo tienes. Filtramos por tipo.
	# Esto evita asumir métodos extra en el repo.
	var enemies: Array = enemy_repo.get_all()
	if enemies.is_empty():
		return {} # debería no ocurrir; si pasa, fallará más abajo y lo verás rápido

	# Filtra por tipo exacto
	var filtered: Array = []
	for e in enemies:
		if typeof(e) == TYPE_DICTIONARY:
			var t := String((e as Dictionary).get("tipo", ""))
			if t == tipo:
				filtered.append(e)

	# Si no hay del tipo pedido, fallback a cualquiera
	if filtered.is_empty():
		return enemies[randi() % enemies.size()]

	return filtered[randi() % filtered.size()]


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

	# mover carta a descarte
	var played: Dictionary = player.hand.pop_at(hand_index)
	player.discard.append(played)

	_check_end_conditions()
	state_changed.emit()


func end_player_turn() -> void:
	# descartar mano
	while player.hand.size() > 0:
		player.discard.append(player.hand.pop_back())

	_enemy_act()
	_check_end_conditions()

	if player.hp > 0 and enemy.hp > 0:
		start_player_turn()


func _enemy_act() -> void:
	var dmg := enemy.damage

	# bloque absorbe primero
	var absorbed := mini(player.block, dmg)
	player.block -= absorbed
	dmg -= absorbed

	player.hp -= dmg
	if player.hp < 0:
		player.hp = 0


func _apply_card_effect(c: Dictionary) -> void:
	var tipo := String(c["tipo"])
	var value := int(c["valor_base"])

	match tipo:
		"ATAQUE":
			enemy.hp = maxi(0, enemy.hp - value)
		"DEFENSA":
			player.block += value
		"HABILIDAD":
			# MVP: "Concentración" => energía +1; resto cura value
			if String(c["nombre"]) == "Concentración":
				player.energy += 1
			else:
				player.hp = mini(player.max_hp, player.hp + value)


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


func _check_end_conditions() -> void:
	if enemy.hp <= 0:
		_on_victory()
		var damage_taken: int = maxi(0, _player_hp_at_start - player.hp)
		var unlocked := achievement_service.on_combat_ended(1, true, enemy.tipo, damage_taken)

		combat_ended.emit(true, enemy.recompensa_xp, enemy.name)
	elif player.hp <= 0:
		combat_ended.emit(false, 0, enemy.name)


func _on_victory() -> void:
	var user_id: int = 1 # MVP: admin
	var xp_gained: int = enemy.recompensa_xp

	# Sumar XP
	Database.execute("""
		UPDATE progreso_usuario
		SET experiencia = experiencia + %d,
		    fecha_ultima_partida = datetime('now')
		WHERE id_usuario = %d;
	""" % [xp_gained, user_id])

	# Subida de nivel simple (cada 100 XP)
	_check_level_up(user_id)


func _check_level_up(user_id: int) -> void:
	var rows := Database.query("""
		SELECT nivel, experiencia
		FROM progreso_usuario
		WHERE id_usuario = %d;
	""" % user_id)

	if rows.is_empty():
		return

	var nivel: int = int(rows[0]["nivel"])
	var xp: int = int(rows[0]["experiencia"])

	var new_level := int(xp / 100) + 1
	if new_level > nivel:
		Database.execute("""
			UPDATE progreso_usuario
			SET nivel = %d
			WHERE id_usuario = %d;
		""" % [new_level, user_id])
		ProgressionService.new().apply_level_unlocks(user_id, new_level)
