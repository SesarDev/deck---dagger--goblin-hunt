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

@onready var btn_end_turn: Button = $VBoxRoot/HBoxActions/BtnEndTurn
@onready var btn_back_to_map: Button = $VBoxRoot/HBoxActions/BtnBackToMap

var combat := CombatManager.new()

func _ready() -> void:
	randomize()

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
			(btn as Button).set_card_data(
				String(c["nombre"]),
				int(c["coste_energia"]),
				String(c["descripcion"])
			)
		else:
			btn.disabled = true
			(btn as Button).set_card_data("-", 0, "")

func _on_card_played(hand_index: int) -> void:
	combat.play_card(hand_index)

func _on_end_turn_pressed() -> void:
	combat.end_player_turn()

func _on_combat_ended(victory: bool, xp_gained: int, enemy_name: String) -> void:
	btn_end_turn.disabled = true

	var slots := [card_1, card_2, card_3, card_4, card_5]
	for b in slots:
		b.disabled = true

	if victory:
		lbl_enemy_intent.text = "VICTORIA"
		_show_result_dialog("Victoria",
			"Has derrotado a %s.\nRecompensa: +%d XP" % [enemy_name, xp_gained]
		)
	else:
		lbl_enemy_intent.text = "DERROTA"
		_show_result_dialog("Derrota",
			"Has sido derrotado por %s." % enemy_name
		)


func _on_back_to_map_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
	
func _show_result_dialog(title_text: String, message: String) -> void:
	var dlg := AcceptDialog.new()
	dlg.title = title_text
	dlg.dialog_text = message
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func():
		dlg.queue_free()
	)
