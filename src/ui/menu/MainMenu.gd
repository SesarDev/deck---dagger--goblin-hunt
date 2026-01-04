extends Control

@onready var btn_jugar: Button = %BtnJugar
@onready var btn_biblioteca: Button = %BtnBiblioteca
@onready var btn_logros: Button = %BtnLogros
@onready var btn_opciones: Button = %BtnOpciones
@onready var btn_salir: Button = %BtnSalir
@onready var btn_profile: Button = %BtnProfile


func _ready() -> void:
	btn_jugar.pressed.connect(_on_btn_jugar_pressed)
	btn_biblioteca.pressed.connect(_on_btn_biblioteca_pressed)
	btn_logros.pressed.connect(_on_btn_logros_pressed)
	btn_opciones.pressed.connect(_on_btn_opciones_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	btn_profile.pressed.connect(_on_profile_pressed)
	ProgressionService.new().refresh_all_unlocks(1)
	
	print(Database.query("SELECT id_enemigo, nombre, vida_base, dano_base, recompensa_xp, tipo FROM enemigo ORDER BY id_enemigo;"))







func _on_btn_jugar_pressed() -> void:
	print("Jugar: ir a mapa/camino")
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")

func _on_btn_biblioteca_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/library/LibraryScene.tscn")

func _on_btn_logros_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/achievements/AchievementsScene.tscn")

func _on_btn_opciones_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/options/OptionsScene.tscn")

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
	
func _on_profile_pressed() -> void:
	get_tree().change_scene_to_file(
        "res://src/scenes/profile/ProfileScene.tscn"
	)
