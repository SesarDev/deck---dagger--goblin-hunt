extends Control

@onready var title_label: Label = $TitleLabel
@onready var users_list: ItemList = $UsersList
@onready var buttons_container: HBoxContainer = $ButtonsContainer
@onready var refresh_button: Button = $ButtonsContainer/RefreshButton
@onready var new_user_button: Button = $ButtonsContainer/NewUserButton
@onready var make_admin_button: Button = $ButtonsContainer/MakeAdminButton
@onready var make_player_button: Button = $ButtonsContainer/MakePlayerButton
@onready var delete_button: Button = $ButtonsContainer/DeleteButton
@onready var back_button: Button = $ButtonsContainer/BackButton
@onready var message_label: Label = $MessageLabel

const LOGIN_SCENE := "res://src/scenes/admin/AdminLogin.tscn"

# Mantenemos un array para mapear índice de ItemList -> user_id
var user_ids: Array[int] = []


func _ready() -> void:
	# Seguridad básica: solo admins
	if not Game.is_admin():
		_set_message("Access denied. Admin only.", Color.RED)
		# Opcional: volver a login directamente
		_go_back_to_login()
		return

	title_label.text = "Admin Panel - Users Management"
	_connect_buttons()
	_refresh_users()

func _connect_buttons() -> void:
	refresh_button.pressed.connect(_refresh_users)
	new_user_button.pressed.connect(_on_new_user_pressed)
	make_admin_button.pressed.connect(_on_make_admin_pressed)
	make_player_button.pressed.connect(_on_make_player_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _refresh_users() -> void:
	users_list.clear()
	user_ids.clear()

	var users = DB.get_all_users()

	for u in users:
		var text = "#%d | %s | %s" % [u.id, u.username, u.role]
		var idx = users_list.add_item(text)
		if idx >= 0:
			user_ids.append(int(u.id))

	_set_message("Loaded %d users from database." % users.size(), Color.WHITE)

func _get_selected_user_id() -> int:
	var idx = users_list.get_selected_items()
	if idx.is_empty():
		_set_message("No user selected.", Color.ORANGE_RED)
		return -1
	var list_index: int = idx[0]
	if list_index < 0 or list_index >= user_ids.size():
		_set_message("Invalid selection.", Color.RED)
		return -1
	return user_ids[list_index]

func _on_new_user_pressed() -> void:
	# Versión simple: creamos un usuario con nombre auto generado.
	var new_username = "user_" + str(Time.get_unix_time_from_system())
	var ok = DB.create_user(new_username, "PLAYER", "")

	if ok:
		_set_message("User created: %s" % new_username, Color.LAWN_GREEN)
		_refresh_users()
	else:
		_set_message("Error creating new user.", Color.RED)

func _on_make_admin_pressed() -> void:
	var uid = _get_selected_user_id()
	if uid == -1:
		return

	var ok = DB.update_user_role(uid, "ADMIN")
	if ok:
		_set_message("User %d is now ADMIN." % uid, Color.LAWN_GREEN)
		_refresh_users()
	else:
		_set_message("Error updating role.", Color.RED)

func _on_make_player_pressed() -> void:
	var uid = _get_selected_user_id()
	if uid == -1:
		return

	var ok = DB.update_user_role(uid, "PLAYER")
	if ok:
		_set_message("User %d is now PLAYER." % uid, Color.LAWN_GREEN)
		_refresh_users()
	else:
		_set_message("Error updating role.", Color.RED)

func _on_delete_pressed() -> void:
	var uid = _get_selected_user_id()
	if uid == -1:
		return

	# Evita borrar al admin por defecto (buena práctica para demo)
	if uid == Game.current_user.id:
		_set_message("Cannot delete current logged-in admin.", Color.ORANGE_RED)
		return

	var ok = DB.delete_user(uid)
	if ok:
		_set_message("User %d deleted." % uid, Color.LAWN_GREEN)
		_refresh_users()
	else:
		_set_message("Error deleting user.", Color.RED)

func _on_back_pressed() -> void:
	_go_back_to_login()

func _go_back_to_login() -> void:
	var scene_res := load(LOGIN_SCENE)
	if scene_res == null:
		push_error("[AdminPanel] Cannot load AdminLogin scene.")
		return
	get_tree().change_scene_to_packed(scene_res)

func _set_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.modulate = color
