extends Control

@onready var btn_cards: Button = %BtnCards
@onready var btn_enemies: Button = %BtnEnemies
@onready var btn_back: Button = %BtnBack

func _ready() -> void:
	btn_cards.pressed.connect(func():
		get_tree().change_scene_to_file("res://src/scenes/admin/AdminCards.tscn")
	)
	btn_enemies.pressed.connect(func():
		get_tree().change_scene_to_file("res://src/scenes/admin/AdminEnemies.tscn")
	)
	btn_back.pressed.connect(func():
		get_tree().change_scene_to_file("res://src/scenes/profile/ProfileScene.tscn")
	)
