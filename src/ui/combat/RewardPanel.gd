extends Control
class_name RewardPanel

signal card_chosen(card_row: Dictionary)

@onready var lbl_title: Label = %LblTitle
@onready var lbl_info: Label = %LblInfo
@onready var hbox_cards: HBoxContainer = %HBoxCards

@export var card_view_scene: PackedScene

func show_rewards(cards: Array, xp: int, gold: int) -> void:
	if card_view_scene == null:
		push_error("RewardPanel: card_view_scene no asignada")
		return

	lbl_title.text = "Elige 1 carta (obligatorio)"
	lbl_info.text = "+%d XP  |  +%d Oro" % [xp, gold]

	for child in hbox_cards.get_children():
		child.queue_free()

	for c in cards:
		var cv := card_view_scene.instantiate() as Button
		cv.custom_minimum_size = Vector2(260, 240)
		hbox_cards.add_child(cv)

		var img_val = c.get("imagen", "")
		var bg_val = c.get("fondo", "")
		var img := "" if img_val == null else String(img_val)
		var bg := "" if bg_val == null else String(bg_val)

		(cv as Button).set_card_data(
			String(c.get("nombre", "Carta")),
			int(c.get("coste_energia", 0)),
			String(c.get("descripcion", "")),
			img,
			bg
		)

		cv.pressed.connect(func():
			card_chosen.emit(c)
		)

	visible = true

func hide_panel() -> void:
	visible = false
