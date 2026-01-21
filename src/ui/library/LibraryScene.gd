# res://src/ui/library/LibraryScene.gd
extends Control

@onready var btn_back: Button = %BtnBack

@onready var search_edit: LineEdit = %SearchEdit
@onready var type_filter: OptionButton = %TypeFilter
@onready var rarity_filter: OptionButton = %RarityFilter
@onready var cost_filter: OptionButton = %CostFilter
@onready var btn_clear: Button = %BtnClearFilters

@onready var grid_cards: GridContainer = %GridCards

@onready var detail_name: Label = %DetailName
@onready var detail_type: Label = %DetailType
@onready var detail_cost: Label = %DetailCost
@onready var detail_rarity: Label = %DetailRarity
@onready var detail_desc: RichTextLabel = %DetailDesc

const CARD_VIEW_SCENE := preload("res://src/ui/common/CardView.tscn")

# Datos desde BD: fila de carta (id_carta, nombre, descripcion, tipo, coste_energia, rareza, disponible)
var cards: Array = []
var filtered_cards: Array = []

const TYPE_DB_TO_UI := {
	"ATAQUE": "Ataque",
	"DEFENSA": "Defensa",
	"HABILIDAD": "Habilidad",
}

const TYPE_UI_TO_DB := {
	"Ataque": "ATAQUE",
	"Defensa": "DEFENSA",
	"Habilidad": "HABILIDAD",
}

const RARITY_DB_TO_UI := {
	"COMUN": "Común",
	"RARO": "Rara",
	"EPICO": "Épica",
	"LEGENDARIO": "Legendaria",
}

const RARITY_UI_TO_DB := {
	"Común": "COMUN",
	"Rara": "RARO",
	"Épica": "EPICO",
	"Legendaria": "LEGENDARIO",
}

func _ready() -> void:
	_init_filters()
	_load_from_db()
	_apply_filters()

	btn_back.pressed.connect(_back)
	btn_clear.pressed.connect(_clear_filters)

	search_edit.text_changed.connect(func(_t): _apply_filters())
	type_filter.item_selected.connect(func(_i): _apply_filters())
	rarity_filter.item_selected.connect(func(_i): _apply_filters())
	cost_filter.item_selected.connect(func(_i): _apply_filters())


func _init_filters() -> void:
	type_filter.clear()
	type_filter.add_item("Tipo: Todos")
	type_filter.add_item("Ataque")
	type_filter.add_item("Defensa")
	type_filter.add_item("Habilidad")

	rarity_filter.clear()
	rarity_filter.add_item("Rareza: Todas")
	rarity_filter.add_item("Común")
	rarity_filter.add_item("Rara")
	rarity_filter.add_item("Épica")
	rarity_filter.add_item("Legendaria")

	cost_filter.clear()
	cost_filter.add_item("Coste: Todos")
	cost_filter.add_item("0")
	cost_filter.add_item("1")
	cost_filter.add_item("2")
	cost_filter.add_item("3+")


func _load_from_db() -> void:
	# Biblioteca de jugador: por defecto solo cartas "disponibles"
	cards = Database.query("""
	SELECT id_carta, nombre, descripcion, tipo, coste_energia, rareza, disponible, imagen, fondo
	FROM carta
	WHERE disponible = 1
	ORDER BY id_carta;
""")



func _apply_filters() -> void:
	var q := search_edit.text.strip_edges().to_lower()

	var type_selected_ui := type_filter.get_item_text(type_filter.selected)
	var rarity_selected_ui := rarity_filter.get_item_text(rarity_filter.selected)
	var cost_selected := cost_filter.get_item_text(cost_filter.selected)

	filtered_cards = []
	for c in cards:
		var nombre := String(c.get("nombre", ""))

		if q != "" and nombre.to_lower().find(q) == -1:
			continue

		# Tipo
		if type_selected_ui != "Tipo: Todos":
			var tipo_db := String(c.get("tipo", ""))
			var tipo_expected := String(TYPE_UI_TO_DB.get(type_selected_ui, ""))
			if tipo_expected == "" or tipo_db != tipo_expected:
				continue

		# Rareza
		if rarity_selected_ui != "Rareza: Todas":
			var rareza_db := String(c.get("rareza", ""))
			var rareza_expected := String(RARITY_UI_TO_DB.get(rarity_selected_ui, ""))
			if rareza_expected == "" or rareza_db != rareza_expected:
				continue

		# Coste
		if cost_selected != "Coste: Todos":
			var cost := int(c.get("coste_energia", 0))
			if cost_selected == "3+" and cost < 3:
				continue
			elif cost_selected != "3+" and cost != int(cost_selected):
				continue

		filtered_cards.append(c)

	_rebuild_grid()


func _rebuild_grid() -> void:
	# Limpiar hijos
	for child in grid_cards.get_children():
		child.queue_free()

	# Rellenar
	for i in range(filtered_cards.size()):
		var c: Dictionary = filtered_cards[i]
		var card_view = CARD_VIEW_SCENE.instantiate()
		grid_cards.add_child(card_view)

		# Ajuste visual para biblioteca
		card_view.custom_minimum_size = Vector2(200, 160)
		card_view.size_flags_horizontal = Control.SIZE_FILL
		card_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		var coste := int(c.get("coste_energia", 0))
		
		var nombre := str(c.get("nombre", ""))
		var desc := str(c.get("descripcion", ""))
		var img := str(c.get("imagen", ""))
		var bg := str(c.get("fondo", ""))


		card_view.set_card_data(nombre, coste, desc, img, bg)

		card_view.pressed.connect(func(): _select_card(c))


func _select_card(c: Dictionary) -> void:
	var nombre := str(c.get("nombre", ""))
	var tipo_db := str(c.get("tipo", ""))
	var rareza_db := str(c.get("rareza", ""))
	var desc := str(c.get("descripcion", ""))

	var coste := int(c.get("coste_energia", 0))

	detail_name.text = "Carta: %s" % nombre
	detail_type.text = "Tipo: %s" % String(TYPE_DB_TO_UI.get(tipo_db, tipo_db))
	detail_cost.text = "Coste: %d" % coste
	detail_rarity.text = "Rareza: %s" % String(RARITY_DB_TO_UI.get(rareza_db, rareza_db))
	detail_desc.text = desc


func _clear_filters() -> void:
	search_edit.text = ""
	type_filter.select(0)
	rarity_filter.select(0)
	cost_filter.select(0)
	_apply_filters()


func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
