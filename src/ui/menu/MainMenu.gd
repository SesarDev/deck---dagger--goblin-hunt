extends Control

@onready var btn_jugar: Button = %BtnJugar
@onready var btn_continuar: Button = %BtnContinuar
@onready var btn_biblioteca: Button = %BtnBiblioteca
@onready var btn_logros: Button = %BtnLogros
@onready var btn_opciones: Button = %BtnOpciones
@onready var btn_salir: Button = %BtnSalir
@onready var btn_profile: Button = %BtnProfile


func _ready() -> void:
	btn_jugar.pressed.connect(_on_btn_jugar_pressed)
	btn_continuar.pressed.connect(_on_btn_continue_pressed)
	btn_biblioteca.pressed.connect(_on_btn_biblioteca_pressed)
	btn_logros.pressed.connect(_on_btn_logros_pressed)
	btn_opciones.pressed.connect(_on_btn_opciones_pressed)
	btn_salir.pressed.connect(_on_btn_salir_pressed)
	btn_profile.pressed.connect(_on_profile_pressed)

	ProgressionService.new().refresh_all_unlocks(1)

	_refresh_continue_button()


func _refresh_continue_button() -> void:
	btn_continuar.disabled = not FileAccess.file_exists(GameState.SAVE_PATH)


func _on_btn_continue_pressed() -> void:
	var loaded := GameState.load_from_disk()
	if not loaded:
		_refresh_continue_button()
		return

	# Si hay run_id, cargamos el mazo de esa run
	if GameState.run_id >= 0:
		DeckManager.load_run_deck(GameState.run_id)
	else:
		push_error("Save inconsistente: run_id inválido")
		return

	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")


func _on_btn_jugar_pressed() -> void:
	GameState.run_id = Database.create_run()
	print("[MENU] run_id creado =", GameState.run_id)
	print("[MENU] run_deck_card =", Database.query("SELECT COUNT(*) AS n FROM run_deck_card WHERE run_id=%d;" % GameState.run_id))


	# 1) Inicializa estado del mapa
	GameState.new_run(randi(), 8)

	# 2) Crea la run en SQLite + genera el starter deck
	GameState.run_id = Database.create_run()

	# 3) Carga el mazo en memoria
	DeckManager.load_run_deck(GameState.run_id)

	# 4) Guarda para habilitar Continuar
	GameState.save_to_disk()
	_refresh_continue_button()

	# 5) Ir al mapa
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
	get_tree().change_scene_to_file("res://src/scenes/profile/ProfileScene.tscn")
