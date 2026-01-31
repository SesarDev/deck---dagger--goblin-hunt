extends Button

@onready var bg: TextureRect = %Bg
@onready var art: TextureRect = %Art

@onready var lbl_name: Label = %CardName
@onready var lbl_cost: Label = %CardCost
@onready var lbl_desc: Label = %CardDescription

# Placeholders para que nunca se vea vacío mientras completas BD / assets
@export var default_bg_path: String = "res://assets/cards/bg_default.png"
@export var default_art_path: String = "res://assets/cards/art_default.png"

func _ready() -> void:
	# Asegura que el click lo recibe el Button, no los hijos.
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_card_data(
	nombre: String,
	coste_energia: int,
	descripcion: String,
	imagen: String = "",
	fondo: String = ""
) -> void:
	lbl_cost.text = str(coste_energia)
	lbl_name.text = nombre
	lbl_desc.text = descripcion

	_fit_label_text(lbl_name, 16, 10)
	_fit_label_text(lbl_desc, 14, 9)

	# Fondo (siempre con fallback)
	_set_texture_safe(bg, fondo.strip_edges(), default_bg_path)

	# Arte (siempre con fallback)
	_set_texture_safe(art, imagen.strip_edges(), default_art_path)




func _pick_path(path: String, fallback: String) -> String:
	var p := path.strip_edges()
	return fallback if p == "" else p


func _set_texture_safe(target: TextureRect, path: String, fallback: String) -> void:
	var tex := load(path) as Texture2D
	if tex == null:
		tex = load(fallback) as Texture2D
	target.texture = tex

func _fit_label_text(label: Label, max_size: int, min_size: int) -> void:
	var font := label.get_theme_font("font")
	if font == null:
		return

	for size in range(max_size, min_size - 1, -1):
		label.add_theme_font_size_override("font_size", size)
		await get_tree().process_frame

		if label.get_minimum_size().x <= label.size.x:
			return

	# Si no cabe ni con el mínimo
	label.add_theme_font_size_override("font_size", min_size)
