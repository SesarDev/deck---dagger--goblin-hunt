extends Control

@onready var btn_back: Button = %BtnBack
@onready var profiles_list: ItemList = %ProfilesList

@onready var profile_name: Label = %ProfileName
@onready var profile_role: Label = %ProfileRole
@onready var stats_label: Label = %StatsLabel
@onready var run_label: Label = %RunLabel

@onready var btn_play: Button = %BtnPlay
@onready var btn_admin: Button = %BtnAdmin

var repo := UserRepository.new()
var selected_user_id: int = -1


func _ready() -> void:
	profiles_list.item_selected.connect(_on_profile_selected)
	btn_back.pressed.connect(_back)
	btn_play.pressed.connect(_play)
	btn_admin.pressed.connect(_open_admin)

	_reload_and_restore()


func _reload_and_restore() -> void:
	var users := repo.get_all()
	_fill_list(users)

	# 1) Restaurar desde GameState si existe
	if GameState.user_id != -1 and _select_by_id(GameState.user_id):
		return

	# 2) Fallback: seleccionar primero
	if profiles_list.item_count > 0:
		profiles_list.select(0)
		profiles_list.grab_focus()
		_on_profile_selected(0)
	else:
		_clear_detail()


func _fill_list(users: Array) -> void:
	profiles_list.clear()

	for u in users:
		var id_usuario := int(u.get("id_usuario", -1))
		var name := String(u.get("nombre_usuario", ""))
		var role := String(u.get("rol", "PLAYER")).to_upper()

		var tag := "[ADMIN] " if role == "ADMIN" else ""
		var idx := profiles_list.add_item(tag + name)
		profiles_list.set_item_metadata(idx, id_usuario)


func _on_profile_selected(list_index: int) -> void:
	if list_index < 0 or list_index >= profiles_list.item_count:
		return

	var id_usuario := int(profiles_list.get_item_metadata(list_index))
	var p := repo.get_profile_summary(id_usuario)
	if p.is_empty():
		return

	selected_user_id = id_usuario

	var name := String(p.get("nombre_usuario", ""))
	var role := String(p.get("rol", "PLAYER")).to_upper()
	var wins := int(p.get("victorias", 0))
	var losses := int(p.get("derrotas", 0))
	var run_id := int(p.get("run_id_activa", -1))

	# Persistimos selección
	GameState.set_active_user(id_usuario, name, role)

	# UI
	profile_name.text = "Nombre: %s" % name
	profile_role.text = "Rol: %s" % role
	stats_label.text = "Victorias: %d | Derrotas: %d" % [wins, losses]

	var run_text := repo.get_run_label(run_id) if run_id > 0 else "—"
	run_label.text = "Run actual: %s" % run_text

	btn_admin.visible = (role == "ADMIN")
	profiles_list.grab_focus()


func _select_by_id(id_usuario: int) -> bool:
	for i in range(profiles_list.item_count):
		if int(profiles_list.get_item_metadata(i)) == id_usuario:
			profiles_list.select(i)
			profiles_list.grab_focus()
			_on_profile_selected(i)
			return true
	return false


func _clear_detail() -> void:
	selected_user_id = -1
	profile_name.text = "Nombre: "
	profile_role.text = "Rol: "
	stats_label.text = "Victorias: | Derrotas: "
	run_label.text = "Run actual: "
	btn_admin.visible = false


func _play() -> void:
	if GameState.user_id == -1:
		push_error("Selecciona un perfil antes de jugar.")
		return
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")


func _open_admin() -> void:
	get_tree().change_scene_to_file("res://src/scenes/admin/AdminHub.tscn")


func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
