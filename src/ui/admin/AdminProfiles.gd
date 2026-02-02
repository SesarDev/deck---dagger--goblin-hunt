extends Control

# UI
@onready var btn_back: Button = %BtnBack
@onready var search_edit: LineEdit = %SearchEdit
@onready var profiles_list: ItemList = %ProfilesList
@onready var btn_new: Button = %BtnNew
@onready var btn_delete: Button = %BtnDelete

@onready var username_edit: LineEdit = %UsernameEdit
@onready var role_option: OptionButton = %RoleOption
@onready var password_edit: LineEdit = %PasswordEdit

@onready var btn_save: Button = %BtnSave
@onready var btn_reset: Button = %BtnReset

# Data
var repo := UserRepository.new()

var users: Array[Dictionary] = []
var filtered_indices: Array[int] = []

var selected_user_index: int = -1
var selected_user_id: int = -1

func _ready() -> void:
	_init_form_options()
	_load_from_db()
	_apply_filter("")

	profiles_list.item_selected.connect(_on_list_selected)
	search_edit.text_changed.connect(func(t): _apply_filter(t))
	btn_new.pressed.connect(_new_user)
	btn_delete.pressed.connect(_delete_user)
	btn_save.pressed.connect(_save_user)
	btn_reset.pressed.connect(_reset_form)
	btn_back.pressed.connect(_back)

func _init_form_options() -> void:
	role_option.clear()
	role_option.add_item("PLAYER")
	role_option.add_item("ADMIN")
	password_edit.secret = true

func _load_from_db() -> void:
	users = repo.get_all()
	selected_user_index = -1
	selected_user_id = -1

func _apply_filter(query: String) -> void:
	var q := query.strip_edges().to_lower()
	profiles_list.clear()
	filtered_indices.clear()

	for i in range(users.size()):
		var u := users[i]
		var name := String(u.get("nombre_usuario", ""))

		if q != "" and name.to_lower().find(q) == -1:
			continue

		filtered_indices.append(i)
		profiles_list.add_item(
			"#%d | %s | %s" % [
				int(u.get("id_usuario", -1)),
				name,
				String(u.get("rol", "PLAYER"))
			]
		)

	if filtered_indices.is_empty():
		selected_user_index = -1
		selected_user_id = -1
		_clear_form()

func _on_list_selected(list_index: int) -> void:
	if list_index < 0 or list_index >= filtered_indices.size():
		return

	selected_user_index = filtered_indices[list_index]
	selected_user_id = int(users[selected_user_index].get("id_usuario", -1))
	_fill_form(users[selected_user_index])

func _fill_form(u: Dictionary) -> void:
	username_edit.text = String(u.get("nombre_usuario", ""))
	password_edit.text = String(u.get("contrasena", ""))
	_select_option_by_text(role_option, String(u.get("rol", "PLAYER")).to_upper())

func _select_option_by_text(ob: OptionButton, text: String) -> void:
	for i in range(ob.item_count):
		if ob.get_item_text(i) == text:
			ob.select(i)
			return
	ob.select(0)

func _new_user() -> void:
	selected_user_index = -1
	selected_user_id = -1
	_clear_form()
	username_edit.text = "player_" + str(Time.get_unix_time_from_system())
	role_option.select(0)

func _save_user() -> void:
	var name := username_edit.text.strip_edges()
	var pwd := password_edit.text
	var role := role_option.get_item_text(role_option.selected)

	if name.is_empty():
		push_error("El nombre no puede estar vacío")
		return

	if repo.exists_username(name, selected_user_id):
		push_error("Ya existe un perfil con ese nombre")
		return

	var data := {
		"nombre_usuario": name,
		"contrasena": pwd,
		"rol": role
	}

	if selected_user_id == -1:
		repo.create(data)
	else:
		repo.update(selected_user_id, data)

	var keep_id := selected_user_id
	_load_from_db()
	_apply_filter(search_edit.text)

	if keep_id != -1:
		_select_by_id(keep_id)
	else:
		_select_by_username(name)


func _delete_user() -> void:
	if selected_user_id == -1:
		return
	if selected_user_id == 1:
		push_error("No se puede borrar el admin por defecto (id 1)")
		return

	repo.delete(selected_user_id)

	selected_user_id = -1
	selected_user_index = -1

	_load_from_db()
	_apply_filter(search_edit.text)

func _reset_form() -> void:
	if selected_user_index != -1:
		_fill_form(users[selected_user_index])
	else:
		_clear_form()

func _clear_form() -> void:
	username_edit.text = ""
	password_edit.text = ""
	role_option.select(0)

func _select_by_id(id_usuario: int) -> void:
	for list_i in range(filtered_indices.size()):
		var real_i := filtered_indices[list_i]
		if int(users[real_i].get("id_usuario", -1)) == id_usuario:
			profiles_list.select(list_i)
			_on_list_selected(list_i)
			return

func _select_by_username(name: String) -> void:
	for list_i in range(filtered_indices.size()):
		var real_i := filtered_indices[list_i]
		if String(users[real_i].get("nombre_usuario", "")) == name:
			profiles_list.select(list_i)
			_on_list_selected(list_i)
			return

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/admin/AdminHub.tscn")
