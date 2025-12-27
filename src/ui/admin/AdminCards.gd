extends Control

# =========================
# UI REFERENCES
# =========================
@onready var btn_back: Button = %BtnBack
@onready var search_edit: LineEdit = %SearchEdit
@onready var cards_list: ItemList = %CardsList
@onready var btn_new: Button = %BtnNew
@onready var btn_delete: Button = %BtnDelete

@onready var name_edit: LineEdit = %NameEdit
@onready var type_option: OptionButton = %TypeOption
@onready var cost_spin: SpinBox = %CostSpin
@onready var rarity_option: OptionButton = %RarityOption
@onready var desc_edit: TextEdit = %DescEdit

@onready var btn_save: Button = %BtnSave
@onready var btn_reset: Button = %BtnReset

# =========================
# DATA
# =========================
var repo := CardRepository.new()

var cards: Array[Dictionary] = []          # cartas cargadas desde BD
var filtered_indices: Array[int] = []      # índices reales en cards
var selected_card_index: int = -1           # índice real en cards

# =========================
# LIFECYCLE
# =========================
func _ready() -> void:
	_init_form_options()
	_load_from_db()
	_apply_filter("")

	cards_list.item_selected.connect(_on_list_selected)
	search_edit.text_changed.connect(func(t): _apply_filter(t))
	btn_new.pressed.connect(_new_card)
	btn_delete.pressed.connect(_delete_card)
	btn_save.pressed.connect(_save_card)
	btn_reset.pressed.connect(_reset_form)
	btn_back.pressed.connect(_back)

# =========================
# INIT
# =========================
func _init_form_options() -> void:
	type_option.clear()
	type_option.add_item("ATAQUE")
	type_option.add_item("DEFENSA")
	type_option.add_item("HABILIDAD")

	rarity_option.clear()
	rarity_option.add_item("COMUN")
	rarity_option.add_item("RARO")
	rarity_option.add_item("EPICO")
	rarity_option.add_item("LEGENDARIO")

	cost_spin.min_value = 0
	cost_spin.max_value = 10
	cost_spin.step = 1

# =========================
# DATA LOAD
# =========================
func _load_from_db() -> void:
	cards = repo.get_all()
	selected_card_index = -1

# =========================
# FILTER & LIST
# =========================
func _apply_filter(query: String) -> void:
	var q := query.strip_edges().to_lower()
	cards_list.clear()
	filtered_indices.clear()

	for i in range(cards.size()):
		var c := cards[i]
		if q != "" and String(c.nombre).to_lower().find(q) == -1:
			continue

		filtered_indices.append(i)
		cards_list.add_item(
			"%s (Coste %d · %s)" % [
				c.nombre,
				c.coste_energia,
				c.rareza
			]
		)

	if filtered_indices.is_empty():
		selected_card_index = -1
		_reset_form()

func _on_list_selected(list_index: int) -> void:
	if list_index < 0 or list_index >= filtered_indices.size():
		return

	selected_card_index = filtered_indices[list_index]
	_fill_form(cards[selected_card_index])

# =========================
# FORM
# =========================
func _fill_form(c: Dictionary) -> void:
	name_edit.text = c.nombre
	desc_edit.text = c.descripcion
	cost_spin.value = int(c.coste_energia)

	_select_option_by_text(type_option, c.tipo)
	_select_option_by_text(rarity_option, c.rareza)

func _select_option_by_text(ob: OptionButton, text: String) -> void:
	for i in range(ob.item_count):
		if ob.get_item_text(i) == text:
			ob.select(i)
			return
	ob.select(0)

func _reset_form() -> void:
	if selected_card_index != -1:
		_fill_form(cards[selected_card_index])
	else:
		name_edit.text = ""
		desc_edit.text = ""
		cost_spin.value = 1
		type_option.select(0)
		rarity_option.select(0)

# =========================
# ACTIONS
# =========================
func _new_card() -> void:
	selected_card_index = -1
	_reset_form()

func _save_card() -> void:
	var data := {
		"nombre": name_edit.text.strip_edges(),
		"descripcion": desc_edit.text.strip_edges(),
		"tipo": type_option.get_item_text(type_option.selected),
		"coste_energia": int(cost_spin.value),
		"valor_base": 0, # MVP: no editable aquí
		"rareza": rarity_option.get_item_text(rarity_option.selected),
		"disponible": 1
	}

	if data.nombre.is_empty():
		push_error("El nombre no puede estar vacío")
		return

	if selected_card_index == -1:
		repo.create(data)
	else:
		var id: int = int(cards[selected_card_index]["id_carta"])

		repo.update(id, data)

	_load_from_db()
	_apply_filter(search_edit.text)

func _delete_card() -> void:
	if selected_card_index == -1:
		return

	var id := int(cards[selected_card_index].id_carta)
	repo.delete(id)

	selected_card_index = -1
	_load_from_db()
	_apply_filter(search_edit.text)

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/admin/AdminHub.tscn")
