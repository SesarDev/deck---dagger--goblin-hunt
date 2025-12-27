extends Control

# Referencias a paneles (opcional, pero útil)
@onready var lbl_player_name: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerName
@onready var lbl_player_hp: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerHP
@onready var lbl_player_energy: Label = $VBoxRoot/HBoxHUD/PlayerPanel/VBoxPlayer/PlayerEnergy

@onready var lbl_enemy_name: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyName
@onready var lbl_enemy_hp: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyHP
@onready var lbl_enemy_intent: Label = $VBoxRoot/HBoxHUD/EnemyPanel/VBoxEnemy/EnemyIntent

# Mano de cartas
@onready var card_1: Button = $VBoxRoot/HBoxHand/Card_1
@onready var card_2: Button = $VBoxRoot/HBoxHand/Card_2
@onready var card_3: Button = $VBoxRoot/HBoxHand/Card_3
@onready var card_4: Button = $VBoxRoot/HBoxHand/Card_4
@onready var card_5: Button = $VBoxRoot/HBoxHand/Card_5

# Botones de acciones
@onready var btn_end_turn: Button = $VBoxRoot/HBoxActions/BtnEndTurn
@onready var btn_back_to_map: Button = $VBoxRoot/HBoxActions/BtnBackToMap

func _ready() -> void:
	_init_dummy_data()
	_connect_signals()

func _init_dummy_data() -> void:
	# Datos de prueba, sin BD aún
	lbl_player_name.text = "Jugador"
	lbl_player_hp.text = "HP: 50/50"
	lbl_player_energy.text = "Energía: 3"

	lbl_enemy_name.text = "Goblin saqueador"
	lbl_enemy_hp.text = "HP: 35/35"
	lbl_enemy_intent.text = "Intención: Atacar (8 daño)"

	# Rellenar cartas de prueba
	(card_1 as Button).set_card_data("Golpe", 1, "Inflige 6 de daño.")
	(card_2 as Button).set_card_data("Defensa", 1, "Obtén 5 de bloque.")
	(card_3 as Button).set_card_data("Golpe fuerte", 2, "Inflige 12 de daño.")
	(card_4 as Button).set_card_data("Grito goblin", 1, "Aplica 2 de Vulnerable.")
	(card_5 as Button).set_card_data("Curar", 1, "Cura 4 de HP.")

func _connect_signals() -> void:
	card_1.pressed.connect(func(): _on_card_played(1))
	card_2.pressed.connect(func(): _on_card_played(2))
	card_3.pressed.connect(func(): _on_card_played(3))
	card_4.pressed.connect(func(): _on_card_played(4))
	card_5.pressed.connect(func(): _on_card_played(5))

	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	btn_back_to_map.pressed.connect(_on_back_to_map_pressed)

func _on_card_played(index: int) -> void:
	print("Carta jugada:", index)
	# Aquí luego: lógica de combate

func _on_end_turn_pressed() -> void:
	print("Fin de turno")
	# Aquí luego: turno del enemigo, etc.

func _on_back_to_map_pressed() -> void:
	print("Volver al mapa (debug)")
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
