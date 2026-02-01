extends Button
class_name CardView

@onready var bg: TextureRect = %Bg
@onready var art: TextureRect = %Art

@onready var lbl_name: Label = %CardName
@onready var lbl_cost: Label = %CardCost
@onready var lbl_desc: Label = %CardDescription


func _ready() -> void:
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE

	art.texture = null


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

	# Fondo: solo si se pasa uno (si no, el que tenga el editor)
	var bg_path := fondo.strip_edges()
	if bg_path != "" and ResourceLoader.exists(bg_path):
		bg.texture = load(bg_path)

	# 🔑 Arte: SIEMPRE se decide aquí (sin await antes)
	var img := imagen.strip_edges()
	if img != "" and ResourceLoader.exists(img):
		art.texture = load(img)
	else:
		art.texture = null

	# Ajuste de texto (SIN await)
	_fit_label_text(lbl_name, 16, 10)
	_fit_label_text(lbl_desc, 14, 9)


func _fit_label_text(label: Label, max_size: int, min_size: int) -> void:
	var font := label.get_theme_font("font")
	if font == null:
		return

	var max_width := label.size.x
	if max_width <= 0.0:
		return

	var text := label.text

	for size in range(max_size, min_size - 1, -1):
		label.add_theme_font_size_override("font_size", size)

		# Medición sin esperar frame: estable y rápido
		var tl := TextLine.new()
		tl.add_string(text, font, size)
		if tl.get_size().x <= max_width:
			return

	label.add_theme_font_size_override("font_size", min_size)
# Llamar cuando la carta se usa
func mark_as_used() -> void:
	disabled = true
	art.texture = null
	lbl_name.text = ""
	lbl_desc.text = ""
	lbl_cost.text = ""
	modulate = Color(0, 0, 0, 1) # negro total
func reset_visual() -> void:
	modulate = Color(1, 1, 1, 1)
	disabled = false
