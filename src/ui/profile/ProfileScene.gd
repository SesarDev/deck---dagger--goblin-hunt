extends Control

@onready var btn_back: Button = %BtnBack
@onready var profiles_list: ItemList = %ProfilesList

@onready var profile_name: Label = %ProfileName
@onready var profile_role: Label = %ProfileRole
@onready var stats_label: Label = %StatsLabel
@onready var run_label: Label = %RunLabel

@onready var btn_play: Button = %BtnPlay
@onready var btn_admin: Button = %BtnAdmin

var profiles := []
var selected_index := -1

func _ready() -> void:
	_load_dummy_profiles()
	_fill_list()

	profiles_list.item_selected.connect(_on_profile_selected)
	btn_back.pressed.connect(_back)
	btn_play.pressed.connect(_play)
	btn_admin.pressed.connect(_open_admin)

	# Selección inicial
	if profiles.size() > 0:
		profiles_list.select(0)
		_on_profile_selected(0)

func _load_dummy_profiles() -> void:
	profiles = [
		{"username":"Andres", "role":"player", "wins":2, "losses":5, "run":"Bosque: Piso 3"},
		{"username":"Admin", "role":"admin", "wins":0, "losses":0, "run":"—"},
		{"username":"Invitado", "role":"player", "wins":0, "losses":1, "run":"Bosque: Piso 1"},
	]

func _fill_list() -> void:
	profiles_list.clear()
	for p in profiles:
		var tag := "[ADMIN] " if p["role"] == "admin" else ""
		profiles_list.add_item(tag + p["username"])

func _on_profile_selected(index: int) -> void:
	selected_index = index
	var p = profiles[index]

	profile_name.text = "Nombre: %s" % p["username"]
	profile_role.text = "Rol: %s" % p["role"]
	stats_label.text = "Victorias: %d | Derrotas: %d" % [p["wins"], p["losses"]]
	run_label.text = "Run actual: %s" % p["run"]

	# Admin visible solo si role == admin (mejor para la demo)
	btn_admin.visible = (p["role"] == "admin")

func _play() -> void:
	# Para la demo: ir al mapa
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")

func _open_admin() -> void:
	get_tree().change_scene_to_file("res://src/scenes/admin/AdminHub.tscn")


func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
