extends Control

@onready var lbl_player_name: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerName
@onready var lbl_player_hp: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerHP
@onready var lbl_player_energy: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerEnergy

@onready var lbl_enemy_name: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyName
@onready var lbl_enemy_hp: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyHP
@onready var lbl_enemy_intent: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyIntent

@onready var enemy_sprite: TextureRect = %EnemySprite

@onready var card_1: Button = $VBoxRoot/HBoxHand/Card_1
@onready var card_2: Button = $VBoxRoot/HBoxHand/Card_2
@onready var card_3: Button = $VBoxRoot/HBoxHand/Card_3
@onready var card_4: Button = $VBoxRoot/HBoxHand/Card_4
@onready var card_5: Button = $VBoxRoot/HBoxHand/Card_5

@onready var lbl_deck_count: Label = %LblDeckCount
#@onready var lbl_hand_count: Label = %LblHandCount
@onready var lbl_discard_count: Label = %LblDiscardCount

@onready var btn_end_turn: Button = $VBoxRoot/HBoxActions/BtnEndTurn
@onready var btn_back_to_map: Button = $VBoxRoot/HBoxActions/BtnBackToMap

var combat := CombatManager.new()
var _started := false

@export var card_view_scene: PackedScene
var reward_service := RewardService.new()
var _reward_choices: Array = []
var _pending_xp: int = 0
var _pending_enemy_name: String = ""

func _ready() -> void:
	randomize()
	if _started:
		return
	_started = true

	
	_connect_signals()

	combat.state_changed.connect(_refresh_ui)
	combat.combat_ended.connect(_on_combat_ended)

	combat.start_combat() # enemigo aleatorio desde BD


func _connect_signals() -> void:
	card_1.pressed.connect(func(): _on_card_played(0))
	card_2.pressed.connect(func(): _on_card_played(1))
	card_3.pressed.connect(func(): _on_card_played(2))
	card_4.pressed.connect(func(): _on_card_played(3))
	card_5.pressed.connect(func(): _on_card_played(4))

	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	btn_back_to_map.pressed.connect(_on_back_to_map_pressed)


func _refresh_ui() -> void:
	# HUD jugador
	lbl_player_name.text = "Jugador"
	lbl_player_hp.text = "HP: %d/%d  (Bloque: %d)" % [combat.player.hp, combat.player.max_hp, combat.player.block]
	lbl_player_energy.text = "Energía: %d/%d" % [combat.player.energy, combat.player.energy_max]

	# HUD enemigo
	lbl_enemy_name.text = combat.enemy.name
	lbl_enemy_hp.text = "HP: %d/%d" % [combat.enemy.hp, combat.enemy.max_hp]
	lbl_enemy_intent.text = "Intención: Atacar (%d daño)" % combat.enemy.damage

	# Imagen enemigo
	var path := combat.enemy.imagen
	if path != "" and ResourceLoader.exists(path):
		enemy_sprite.texture = load(path)
	else:
		enemy_sprite.texture = null

	# Mano (5 slots)
	var slots := [card_1, card_2, card_3, card_4, card_5]
	for i in range(slots.size()):
		var btn: Button = slots[i]

		if i < combat.player.hand.size():
			var c := combat.player.hand[i]
			btn.disabled = false

			var nombre := str(c.get("nombre", ""))
			var coste := int(c.get("coste_energia", 0))
			var desc := str(c.get("descripcion", ""))

			var img := str(c.get("imagen", ""))
			var bg := str(c.get("fondo", ""))

			(btn as Button).set_card_data(nombre, coste, desc, img, bg)
		else:
			btn.disabled = true
			(btn as Button).set_card_data("-", 0, "", "", "")
	
	# Contadores de cartas
	lbl_deck_count.text = "Mazo: %d" % combat.player.deck.size()
	#lbl_hand_count.text = "Mano: %d" % combat.player.hand.size()
	lbl_discard_count.text = "Usadas: %d" % combat.player.discard.size()



func _on_card_played(hand_index: int) -> void:
	combat.play_card(hand_index)


func _on_end_turn_pressed() -> void:
	combat.end_player_turn()


func _on_combat_ended(victory: bool, xp_gained: int, enemy_name: String) -> void:
	btn_end_turn.disabled = true

	var slots := [card_1, card_2, card_3, card_4, card_5]
	for b in slots:
		b.disabled = true

	# Evita volver al mapa saltándose la recompensa/resultado
	btn_back_to_map.disabled = true

	if victory:
		lbl_enemy_intent.text = "VICTORIA"
		_pending_xp = xp_gained
		_pending_enemy_name = enemy_name
		_show_reward_choice_dialog()

	else:
		lbl_enemy_intent.text = "DERROTA"
		_show_defeat_dialog(enemy_name)


func _on_back_to_map_pressed() -> void:
	# Por seguridad, si el combate no ha terminado, permite salir (si lo quieres).
	# Si prefieres bloquear siempre, deja el botón deshabilitado al inicio.
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")

func _show_reward_choice_dialog() -> void:
	if card_view_scene == null:
		push_error("Reward UI: card_view_scene no asignada (arrastra CardView.tscn en el inspector).")
		return

	var user_id: int = 1
	_reward_choices = reward_service.get_combat_reward_choices(user_id, 3)

	var dlg := AcceptDialog.new()
	dlg.title = "Recompensa"
	dlg.dialog_text = (
		"Has derrotado a %s.\n" % _pending_enemy_name +
		"+%d XP\n\n" % _pending_xp +
		"Elige 1 carta (obligatorio):"
	)

	# Elección obligatoria
	dlg.get_ok_button().visible = false
	dlg.close_requested.connect(func(): pass)
	dlg.exclusive = true

	add_child(dlg)

	# Contenedor horizontal para 3 CardView
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(820, 260)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dlg.add_child(hbox)

	for i in range(_reward_choices.size()):
		var c: Dictionary = _reward_choices[i]

		var cv := card_view_scene.instantiate() as Button
		cv.custom_minimum_size = Vector2(260, 240)
		hbox.add_child(cv)

		# Normaliza posibles nulls de BD (evita "res://<null>")
		var img_val = c.get("imagen", "")
		var bg_val = c.get("fondo", "")
		var img := "" if img_val == null else String(img_val)
		var bg := "" if bg_val == null else String(bg_val)

		# CardView.gd: set_card_data(nombre, coste, desc, imagen_path, fondo_path)
		(cv as Button).set_card_data(
			String(c.get("nombre", "Carta")),
			int(c.get("coste_energia", 0)),
			String(c.get("descripcion", "")),
			img,
			bg
		)

		cv.pressed.connect(func():
			_on_reward_card_chosen(c)
			dlg.queue_free()
		)

	dlg.popup_centered()

	
func _on_reward_card_chosen(card_row: Dictionary) -> void:
	var run_id: int = GameState.run_id
	if run_id <= 0:
		push_error("Recompensa: run_id inválido")
		return

	var card_id: int = int(card_row.get("id_carta", 0))
	if card_id <= 0:
		push_error("Recompensa: card_id inválido")
		return

	# 1) Añadir carta al mazo de la run
	reward_service.add_card_to_run(run_id, card_id)

	# 2) Otorgar oro (ajusta cantidad como quieras)
	var gold_reward: int = 20
	reward_service.add_gold_to_run(run_id, gold_reward)

	print("[REWARD] Añadida carta id=", card_id, " +", gold_reward, " oro (run_id=", run_id, ")")
	
	print(Database.query("SELECT COUNT(*) AS n FROM run_deck_card WHERE run_id=%d;" % GameState.run_id))
	print(Database.query("SELECT gold FROM run WHERE id=%d;" % GameState.run_id))

	_finish_combat_and_return_to_map()


func _finish_combat_and_return_to_map() -> void:
	var cur_id := GameState.current_node_id
	GameState.cleared[cur_id] = true
	GameState.save_to_disk()
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")

#CODIGO ANTIGÜO
func _show_victory_reward_dialog(xp_gained: int, enemy_name: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Recompensa"
	dlg.dialog_text = (
		"Has derrotado a %s.\n\n" % enemy_name +
		"Recompensas:\n" +
		"• +%d XP\n\n" % xp_gained +
		"Pulsa Continuar para volver al mapa."
	)
	dlg.ok_button_text = "Continuar"

	add_child(dlg)
	dlg.popup_centered()

	dlg.confirmed.connect(func():
		var cur_id := GameState.current_node_id

		# Marca el nodo como completado para desbloquear la siguiente columna
		GameState.cleared[cur_id] = true

		# Si tienes gestión de XP global, aquí es donde se aplicaría
		# GameState.add_xp(xp_gained)

		GameState.save_to_disk() # opcional, recomendable
		dlg.queue_free()

		get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
	)


func _show_defeat_dialog(enemy_name: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Derrota"
	dlg.dialog_text = "Has sido derrotado por %s.\n\nPulsa Continuar para volver al mapa." % enemy_name
	dlg.ok_button_text = "Continuar"

	add_child(dlg)
	dlg.popup_centered()

	dlg.confirmed.connect(func():
		GameState.save_to_disk() # opcional
		dlg.queue_free()

		get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
	)
