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

var cards: Array = []
var filtered_cards: Array = []

func _ready() -> void:
	_init_filters()
	_load_dummy_cards()
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

	cost_filter.clear()
	cost_filter.add_item("Coste: Todos")
	cost_filter.add_item("0")
	cost_filter.add_item("1")
	cost_filter.add_item("2")
	cost_filter.add_item("3+")

func _load_dummy_cards() -> void:
	cards = [
		{"name":"Golpe", "type":"Ataque", "rarity":"Común", "cost":1, "desc":"Inflige 6 de daño."},
		{"name":"Defensa", "type":"Defensa", "rarity":"Común", "cost":1, "desc":"Obtén 5 de bloque."},
		{"name":"Cuchillada Goblin", "type":"Ataque", "rarity":"Rara", "cost":2, "desc":"Inflige 10 de daño. Aplica 1 Vulnerable."},
		{"name":"Pisotón", "type":"Ataque", "rarity":"Común", "cost":2, "desc":"Inflige 8 de daño."},
		{"name":"Camuflaje", "type":"Habilidad", "rarity":"Épica", "cost":1, "desc":"Gana 2 Sigilo."},
		{"name":"Trampa de madera", "type":"Habilidad", "rarity":"Rara", "cost":0, "desc":"Aplica 2 Debilitado."},
		{"name":"Escudo improvisado", "type":"Defensa", "rarity":"Rara", "cost":2, "desc":"Obtén 12 de bloque."},
		{"name":"Furia verde", "type":"Habilidad", "rarity":"Épica", "cost":3, "desc":"Gana 2 Fuerza."},
	]

func _apply_filters() -> void:
	var q := search_edit.text.strip_edges().to_lower()

	var type_selected := type_filter.get_item_text(type_filter.selected)
	var rarity_selected := rarity_filter.get_item_text(rarity_filter.selected)
	var cost_selected := cost_filter.get_item_text(cost_filter.selected)

	filtered_cards = []
	for c in cards:
		if q != "" and String(c["name"]).to_lower().find(q) == -1:
			continue

		# Tipo
		if type_selected != "Tipo: Todos" and c["type"] != type_selected:
			continue

		# Rareza
		if rarity_selected != "Rareza: Todas" and c["rarity"] != rarity_selected:
			continue

		# Coste
		if cost_selected != "Coste: Todos":
			if cost_selected == "3+" and int(c["cost"]) < 3:
				continue
			elif cost_selected != "3+" and int(c["cost"]) != int(cost_selected):
				continue

		filtered_cards.append(c)

	_rebuild_grid()

func _rebuild_grid() -> void:
	# Limpiar hijos
	for child in grid_cards.get_children():
		child.queue_free()

	# Rellenar
	for i in range(filtered_cards.size()):
		var c = filtered_cards[i]
		var card_view = CARD_VIEW_SCENE.instantiate()
		grid_cards.add_child(card_view)

		# Ajuste visual para biblioteca
		card_view.custom_minimum_size = Vector2(200, 160)
		card_view.size_flags_horizontal = Control.SIZE_FILL
		card_view.size_flags_vertical = 0
		card_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		card_view.set_card_data(c["name"], int(c["cost"]), c["desc"])
		card_view.pressed.connect(func(): _select_card(c))

func _select_card(c: Dictionary) -> void:
	detail_name.text = "Carta: %s" % c["name"]
	detail_type.text = "Tipo: %s" % c["type"]
	detail_cost.text = "Coste: %d" % int(c["cost"])
	detail_rarity.text = "Rareza: %s" % c["rarity"]
	detail_desc.text = c["desc"]

func _clear_filters() -> void:
	search_edit.text = ""
	type_filter.select(0)
	rarity_filter.select(0)
	cost_filter.select(0)
	_apply_filters()

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
