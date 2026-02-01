extends Control

@onready var lbl_player_name: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerName
@onready var lbl_player_hp: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerHP
@onready var lbl_player_energy: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerEnergy

@onready var lbl_enemy_name: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyName
@onready var lbl_enemy_hp: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyHP
@onready var lbl_enemy_intent: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyIntent

@onready var enemy_sprite: TextureRect = %EnemySprite

# 👇 TIPADO CORRECTO: son CardView (extiende Button)
@onready var card_1: CardView = $VBoxRoot/HBoxHand/Card_1
@onready var card_2: CardView = $VBoxRoot/HBoxHand/Card_2
@onready var card_3: CardView = $VBoxRoot/HBoxHand/Card_3
@onready var card_4: CardView = $VBoxRoot/HBoxHand/Card_4
@onready var card_5: CardView = $VBoxRoot/HBoxHand/Card_5

@onready var lbl_deck_count: Label = %LblDeckCount
@onready var lbl_discard_count: Label = %LblDiscardCount

@onready var btn_end_turn: Button = $VBoxRoot/HBoxActions/BtnEndTurn
@onready var btn_back_to_map: Button = $VBoxRoot/HBoxActions/BtnBackToMap

@export var reward_panel_scene: PackedScene
var reward_panel: RewardPanel

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

	# 1) Instanciar RewardPanel ANTES del combate
	if reward_panel_scene != null:
		reward_panel = reward_panel_scene.instantiate() as RewardPanel
		add_child(reward_panel)
		reward_panel.visible = false
		reward_panel.card_chosen.connect(_on_reward_card_chosen)
	else:
		push_error("CombatScene: reward_panel_scene no asignada")
		return  # sin panel, no seguimos

	# 2) Ahora sí, iniciar combate
	combat.start_combat()


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

	# Mano (5 slots fijos)
	var slots: Array[CardView] = [card_1, card_2, card_3, card_4, card_5]
	for i in range(slots.size()):
		var view: CardView = slots[i]

		if i < combat.player.hand.size():
			var c := combat.player.hand[i]

			# ✅ Asegura que si estaba "usada/negra" vuelve a normal
			view.reset_visual()

			var nombre := str(c.get("nombre", ""))
			var coste := int(c.get("coste_energia", 0))
			var desc := str(c.get("descripcion", ""))

			var img_val = c.get("imagen", "")
			var bg_val = c.get("fondo", "")
			var img := "" if img_val == null else String(img_val)
			var bg := "" if bg_val == null else String(bg_val)

			view.set_card_data(nombre, coste, desc, img, bg)
		else:
			# ✅ Slot vacío: negro y sin arte
			view.disabled = true
			view.modulate = Color(0, 0, 0, 1)

			# Si quieres que el slot vacío NO muestre textos:
			view.set_card_data("", 0, "", "", "")
			# Si prefieres mantener "-" y "0", usa:
			# view.set_card_data("-", 0, "", "", "")

	# Contadores
	lbl_deck_count.text = "Mazo: %d" % combat.player.deck.size()
	lbl_discard_count.text = "Usadas: %d" % combat.player.discard.size()


func _on_card_played(hand_index: int) -> void:
	if hand_index < 0 or hand_index >= combat.player.hand.size():
		return

	var c := combat.player.hand[hand_index]
	var cost := int(c.get("coste_energia", 0))
	if combat.player.energy < cost:
		return

	var slots: Array[CardView] = [card_1, card_2, card_3, card_4, card_5]
	var view := slots[hand_index]

	#  La carta queda negra (no se mueve)
	view.mark_as_used()

	combat.play_card(hand_index)



func _on_end_turn_pressed() -> void:
	combat.end_player_turn()


func _on_combat_ended(victory: bool, xp_gained: int, enemy_name: String) -> void:
	btn_end_turn.disabled = true

	var slots: Array[CardView] = [card_1, card_2, card_3, card_4, card_5]
	for b in slots:
		b.disabled = true

	# Evita volver al mapa saltándose la recompensa/resultado
	btn_back_to_map.disabled = true

	if victory:
		lbl_enemy_intent.text = "VICTORIA"
		_pending_enemy_name = enemy_name
		_pending_xp = xp_gained

		var gold_reward := 20
		var cards := reward_service.get_combat_reward_choices(1, 3)

		if reward_panel != null:
			reward_panel.show_rewards(cards, _pending_xp, gold_reward)
		else:
			push_error("RewardPanel no instanciado")
	else:
		lbl_enemy_intent.text = "DERROTA"
		_show_defeat_dialog(enemy_name)


func _on_back_to_map_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")


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

	# 2) Otorgar oro
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


func _show_defeat_dialog(enemy_name: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Derrota"
	dlg.dialog_text = "Has sido derrotado por %s.\n\nPulsa Continuar para volver al mapa." % enemy_name
	dlg.ok_button_text = "Continuar"

	add_child(dlg)
	dlg.popup_centered()

	dlg.confirmed.connect(func():
		GameState.save_to_disk()
		dlg.queue_free()
		get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
	)
