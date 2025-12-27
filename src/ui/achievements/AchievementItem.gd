extends Button

@onready var status_dot: ColorRect = $HBox/StatusDot
@onready var ach_name: Label = $HBox/Texts/AchName
@onready var ach_short: Label = $HBox/Texts/AchShort
@onready var ach_state: Label = $HBox/AchState

var data: Dictionary

func set_data(d: Dictionary) -> void:
	data = d
	ach_name.text = d["name"]
	ach_short.text = d["short"]
	ach_state.text = d["state"]

	# Verde si completado, rojo oscuro si bloqueado
	if d["completed"]:
		status_dot.color = Color(0.12, 0.55, 0.20)
	else:
		status_dot.color = Color(0.50, 0.12, 0.12)
