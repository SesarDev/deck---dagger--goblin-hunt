extends Control

@onready var title_label: Label = $TitleLabel
@onready var username_input: LineEdit = $UsernameInput
@onready var login_button: Button = $LoginButton
@onready var message_label: Label = $MessageLabel

const ADMIN_PANEL_SCENE := "res://src/scenes/admin/AdminPanel.tscn"

func _ready() -> void:
	title_label.text = "Deck & Dagger - Login"
	message_label.text = ""
	login_button.pressed.connect(_on_login_button_pressed)

func _on_login_button_pressed() -> void:
	var username := username_input.text.strip_edges()

	if username.is_empty():
		_set_message("Please enter a username.", Color.ORANGE_RED)
		return

	# Iniciamos sesión o registramos si no existe
	Game.login_or_register(username, false)

	if not Game.is_logged_in():
		_set_message("Login failed. Check database.", Color.RED)
		return

	if Game.is_admin():
		_set_message("Welcome, admin: %s" % username, Color.LAWN_GREEN)
		_go_to_admin_panel()
	else:
		_set_message("User '%s' is not ADMIN. Access denied." % username, Color.ORANGE_RED)

func _go_to_admin_panel() -> void:
	var scene_res := load(ADMIN_PANEL_SCENE)
	if scene_res == null:
		push_error("[AdminLogin] Cannot load AdminPanel scene.")
		return

	get_tree().change_scene_to_packed(scene_res)

func _set_message(text: String, color: Color) -> void:
	message_label.text = text
	message_label.modulate = color
