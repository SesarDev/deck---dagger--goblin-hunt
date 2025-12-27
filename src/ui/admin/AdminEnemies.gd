extends Control

@onready var btn_back: Button = %BtnBack
@onready var search_edit: LineEdit = %SearchEdit
@onready var enemies_list: ItemList = %EnemiesList
@onready var btn_new: Button = %BtnNew
@onready var btn_delete: Button = %BtnDelete

@onready var name_edit: LineEdit = %NameEdit
@onready var type_option: OptionButton = %TypeOption
@onready var hp_spin: SpinBox = %HpSpin
@onready var dmg_spin: SpinBox = %DmgSpin
@onready var desc_edit: TextEdit = %DescEdit

@onready var btn_save: Button = %BtnSave
@onready var btn_reset: Button = %BtnReset

# Datos dummy (más adelante vendrán de SQLite)
var enemies: Array[Dictionary] = []
var filtered_indices: Array[int] = []
var selected_enemy_index: int = -1 # índice real dentro de enemies

func _ready() -> void:
	_init_form_options()
	_load_dummy()
	_apply_filter("")

	enemies_list.item_selected.connect(_on_list_selected)
	search_edit.text_changed.connect(func(t): _apply_filter(t))
	btn_new.pressed.connect(_new_enemy)
	btn_delete.pressed.connect(_delete_enemy)
	btn_save.pressed.connect(_save_enemy)
	btn_reset.pressed.connect(_reset_form)
	btn_back.pressed.connect(_back)

func _init_form_options() -> void:
	type_option.clear()
	type_option.add_item("Normal")
	type_option.add_item("Élite")
	type_option.add_item("Jefe")

	hp_spin.min_value = 1
	hp_spin.max_value = 999
	hp_spin.step = 1

	dmg_spin.min_value = 0
	dmg_spin.max_value = 999
	dmg_spin.step = 1

func _load_dummy() -> void:
	enemies = [
		{
			"id": 1,
			"name": "Goblin saqueador",
			"type": "Normal",
			"hp": 35,
			"dmg": 8,
			"desc": "Ataca rápido y huye entre los árboles."
		},
		{
			"id": 2,
			"name": "Goblin con escudo",
			"type": "Normal",
			"hp": 42,
			"dmg": 6,
			"desc": "Bloquea parte del daño recibido."
		},
		{
			"id": 3,
			"name": "Chamán del poblado",
			"type": "Élite",
			"hp": 60,
			"dmg": 10,
			"desc": "Lanza maldiciones y refuerza a otros goblins."
		},
		{
			"id": 4,
			"name": "Jefe: Rey Goblin",
			"type": "Jefe",
			"hp": 120,
			"dmg": 14,
			"desc": "El líder del poblado. Golpes pesados y órdenes a sus súbditos."
		},
	]

func _apply_filter(query: String) -> void:
	var q := query.strip_edges().to_lower()
	enemies_list.clear()
	filtered_indices.clear()

	for i in range(enemies.size()):
		var e = enemies[i]
		if q != "" and String(e["name"]).to_lower().find(q) == -1:
			continue

		filtered_indices.append(i)

		# Texto resumen en la lista
		var line := "%s (%s · HP %d · DMG %d)" % [e["name"], e["type"], int(e["hp"]), int(e["dmg"])]
		enemies_list.add_item(line)

	# Si tras filtrar no hay nada, limpia formulario
	if filtered_indices.is_empty():
		selected_enemy_index = -1
		_clear_form()

func _on_list_selected(list_index: int) -> void:
	if list_index < 0 or list_index >= filtered_indices.size():
		return
	selected_enemy_index = filtered_indices[list_index]
	_fill_form(enemies[selected_enemy_index])

func _fill_form(e: Dictionary) -> void:
	name_edit.text = e["name"]
	_select_option_by_text(type_option, e["type"])
	hp_spin.value = int(e["hp"])
	dmg_spin.value = int(e["dmg"])
	desc_edit.text = e["desc"]

func _select_option_by_text(ob: OptionButton, text: String) -> void:
	for i in range(ob.item_count):
		if ob.get_item_text(i) == text:
			ob.select(i)
			return
	ob.select(0)

func _new_enemy() -> void:
	selected_enemy_index = -1
	name_edit.text = ""
	type_option.select(0)
	hp_spin.value = 30
	dmg_spin.value = 5
	desc_edit.text = ""
	print("AdminEnemies: nuevo registro (demo)")

func _delete_enemy() -> void:
	if selected_enemy_index == -1:
		print("AdminEnemies: nada seleccionado para borrar")
		return

	print("AdminEnemies: borrar", enemies[selected_enemy_index]["name"])
	enemies.remove_at(selected_enemy_index)
	selected_enemy_index = -1
	_apply_filter(search_edit.text)

func _save_enemy() -> void:
	var e := {
		"id": _next_id(),
		"name": name_edit.text.strip_edges(),
		"type": type_option.get_item_text(type_option.selected),
		"hp": int(hp_spin.value),
		"dmg": int(dmg_spin.value),
		"desc": desc_edit.text.strip_edges(),
	}

	if e["name"] == "":
		print("AdminEnemies: nombre vacío, no guardo")
		return

	if selected_enemy_index == -1:
		enemies.append(e)
		print("AdminEnemies: creado", e["name"])
	else:
		# Mantener el id original
		e["id"] = enemies[selected_enemy_index]["id"]
		enemies[selected_enemy_index] = e
		print("AdminEnemies: actualizado", e["name"])

	_apply_filter(search_edit.text)

func _next_id() -> int:
	var max_id := 0
	for e in enemies:
		max_id = maxi(max_id, int(e["id"]))
	return max_id + 1

func _reset_form() -> void:
	# Si hay selección, recarga el enemigo actual; si no, deja el form limpio
	if selected_enemy_index != -1:
		_fill_form(enemies[selected_enemy_index])
	else:
		_clear_form()

func _clear_form() -> void:
	name_edit.text = ""
	type_option.select(0)
	hp_spin.value = 30
	dmg_spin.value = 5
	desc_edit.text = ""

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/admin/AdminHub.tscn")
