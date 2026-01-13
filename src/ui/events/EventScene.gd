extends Control

@onready var btn_option1: Button = %BtnOption1
@onready var btn_option2: Button = %BtnOption2
@onready var btn_option3: Button = %BtnOption3

@onready var result_panel: Panel = %ResultPanel
@onready var result_label: Label = %ResultLabel

@onready var btn_continue: Button = %BtnContinue

var chosen: bool = false
var chosen_option: int = -1


func _ready() -> void:
	# Estado inicial (bloqueante)
	result_panel.visible = false
	btn_continue.visible = false
	btn_continue.disabled = true

	btn_option1.pressed.connect(func(): _choose_option(1))
	btn_option2.pressed.connect(func(): _choose_option(2))
	btn_option3.pressed.connect(func(): _choose_option(3))
	btn_continue.pressed.connect(_back_to_map)

	# Debug
	print(Database.query("SELECT nivel, experiencia FROM progreso_usuario WHERE id_usuario = 1;"))


func _choose_option(i: int) -> void:
	if chosen:
		return

	chosen = true
	chosen_option = i

	# Deshabilitar opciones tras elegir
	btn_option1.disabled = true
	btn_option2.disabled = true
	btn_option3.disabled = true

	# Mostrar resultado/recompensa
	result_panel.visible = true
	result_label.text = _get_result_text(i)

	# Habilitar continuar
	btn_continue.visible = true
	btn_continue.disabled = false

	print("Opción elegida:", i)


func _get_result_text(i: int) -> String:
	# Aquí puedes conectar con recompensas reales (oro/xp/cartas).
	# Por ahora dejo feedback claro, y en _back_to_map se marca el nodo como completado.
	match i:
		1:
			return "Ayudas al goblin.\nRecompensa: una carta envuelta en cuero."
		2:
			return "Robas suministros.\nRecompensa: oro, pero sales herido en la huida."
		3:
			return "Ignoras la aldea.\nRecompensa: ninguna, pero avanzas sin riesgos."
		_:
			return "Ocurre algo inesperado."


func _back_to_map() -> void:
	# 1) Marcar nodo actual como completado (esto desbloquea la siguiente columna)
	var cur_id := GameState.current_node_id
	GameState.cleared[cur_id] = true

	GameState.save_to_disk() 
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
