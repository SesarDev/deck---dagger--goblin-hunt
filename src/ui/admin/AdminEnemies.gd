extends Control

# ============================================================================
# AdminEnemies.gd
# Panel de administración para gestionar enemigos (CRUD) desde la UI.
# - Carga enemigos desde la BD (EnemyRepository)
# - Permite filtrar por nombre
# - Permite crear, editar y borrar
# - Permite seleccionar imagen desde res://assets/enemies
# ============================================================================

# --- Referencias a nodos de UI (inyectadas por nombre único %NodeName) ---
@onready var btn_back: Button = %BtnBack
@onready var search_edit: LineEdit = %SearchEdit
@onready var enemies_list: ItemList = %EnemiesList
@onready var btn_new: Button = %BtnNew
@onready var btn_delete: Button = %BtnDelete

@onready var name_edit: LineEdit = %NameEdit
@onready var type_option: OptionButton = %TypeOption
@onready var hp_spin: SpinBox = %HpSpin
@onready var dmg_spin: SpinBox = %DmgSpin
@onready var image_option: OptionButton = %ImageOption
@onready var desc_edit: TextEdit = %DescEdit

@onready var btn_save: Button = %BtnSave
@onready var btn_reset: Button = %BtnReset

# --- Estado de selección / datos ---
# Enemies se mantiene como "filas" en formato Dictionary (tal cual vienen de BD).
# filtered_indices relaciona el índice visual del ItemList con el índice real en `enemies`.
var enemies: Array[Dictionary] = []
var filtered_indices: Array[int] = []

# Para edición/ borrado se usa el ID real de BD (evita problemas si el listado está filtrado).
var selected_enemy_id: int = -1

# Se conserva `selected_enemy_index` para recargar en reset cuando hay selección.
var selected_enemy_index: int = -1

# Mapeo entre índices del OptionButton de imágenes y rutas reales en disco.
# Ejemplo: image_option index 0 => "", index 1 => "res://assets/enemies/goblin.png", etc.
var _image_paths_by_index: Array[String] = []

# Repositorio (capa de acceso a datos). Debe exponer: get_all(), create(), update(), delete().
var repo := EnemyRepository.new()


# ============================================================================
# Ciclo de vida / Inicialización
# ============================================================================

func _ready() -> void:
	# 1) Inicializa opciones del formulario (tipos, imágenes y rangos de SpinBox)
	_init_form_options()

	# 2) Carga datos desde BD y refresca la lista
	_load_from_db()
	_apply_filter("")

	# 3) Conecta señales de UI (eventos)
	enemies_list.item_selected.connect(_on_list_selected)
	search_edit.text_changed.connect(func(t): _apply_filter(t))
	btn_new.pressed.connect(_new_enemy)
	btn_delete.pressed.connect(_delete_enemy)
	btn_save.pressed.connect(_save_enemy)
	btn_reset.pressed.connect(_reset_form)
	btn_back.pressed.connect(_back)


# ============================================================================
# Capa de datos (lectura desde repositorio)
# ============================================================================

func _load_from_db() -> void:
	enemies = repo.get_all()


# ============================================================================
# Configuración de formulario
# ============================================================================

func _init_form_options() -> void:
	# Tipos disponibles (deben ser coherentes con lo que guardas en BD).
	type_option.clear()
	type_option.add_item("Normal")
	type_option.add_item("Élite")
	type_option.add_item("Jefe")

	# Carga dinámicamente imágenes disponibles en res://assets/enemies
	_init_image_option()

	# Límites básicos de estadísticas para evitar valores inválidos
	hp_spin.min_value = 1
	hp_spin.max_value = 999
	hp_spin.step = 1

	dmg_spin.min_value = 0
	dmg_spin.max_value = 999
	dmg_spin.step = 1


func _init_image_option() -> void:
	# Rellena el OptionButton con archivos de imagen disponibles (png/webp/jpg/jpeg).
	# Además, mantiene un array paralelo con la ruta real para guardar en BD.
	image_option.clear()
	_image_paths_by_index.clear()

	# Primera opción: sin imagen (ruta vacía)
	image_option.add_item("— Sin imagen —")
	_image_paths_by_index.append("")

	var dir := DirAccess.open("res://assets/enemies")
	if dir == null:
		print("AdminEnemies: no se pudo abrir res://assets/enemies")
		return

	dir.list_dir_begin()
	var file := dir.get_next()

	while file != "":
		if not dir.current_is_dir():
			var ext := file.get_extension().to_lower()
			if ext in ["png", "webp", "jpg", "jpeg"]:
				var base := file.get_basename() # nombre sin extensión
				var label := base.replace("_", " ")
				image_option.add_item(label)
				_image_paths_by_index.append("res://assets/enemies/%s" % file)

		file = dir.get_next()

	dir.list_dir_end()


# ============================================================================
# Listado + filtrado
# ============================================================================

func _apply_filter(query: String) -> void:
	# Filtra por nombre (campo `nombre`) en minúsculas.
	# Reconstruye el ItemList y recalcula filtered_indices.
	var q := query.strip_edges().to_lower()

	enemies_list.clear()
	filtered_indices.clear()

	for i in range(enemies.size()):
		var e = enemies[i]

		if q != "" and String(e.get("nombre", "")).to_lower().find(q) == -1:
			continue

		# Guardamos el índice real dentro de `enemies` para mapear selección visual => dato real
		filtered_indices.append(i)

		# Línea compacta para el listado (nombre + tipo + stats clave)
		var line := "%s (%s · HP %d · DMG %d)" % [
			e.get("nombre", ""),
			e.get("tipo", "NORMAL"),
			int(e.get("vida_base", 0)),
			int(e.get("dano_base", 0))
		]
		enemies_list.add_item(line)

	# Si el filtro deja vacío el listado, resetea selección y limpia formulario
	if filtered_indices.is_empty():
		selected_enemy_index = -1
		selected_enemy_id = -1
		_clear_form()


func _on_list_selected(list_index: int) -> void:
	# Traduce la selección visual (list_index) al índice real dentro de `enemies`.
	if list_index < 0 or list_index >= filtered_indices.size():
		return

	selected_enemy_index = filtered_indices[list_index]
	selected_enemy_id = int(enemies[selected_enemy_index]["id_enemigo"])

	_fill_form(enemies[selected_enemy_index])


# ============================================================================
# Relleno / lectura del formulario
# ============================================================================

func _fill_form(e: Dictionary) -> void:
	# Vuelca un enemigo en los campos del formulario.
	name_edit.text = String(e.get("nombre", ""))
	_select_option_by_text(type_option, String(e.get("tipo", "NORMAL")))
	hp_spin.value = int(e.get("vida_base", 10))
	dmg_spin.value = int(e.get("dano_base", 1))
	desc_edit.text = String(e.get("descripcion", ""))

	# Sincroniza la imagen seleccionada con el OptionButton
	var img_path := String(e.get("imagen", ""))
	var idx := _image_paths_by_index.find(img_path)
	if idx == -1:
		idx = 0
	image_option.select(idx)


func _select_option_by_text(ob: OptionButton, text: String) -> void:
	# Selecciona el primer ítem cuyo texto coincide (útil al cargar desde BD).
	for i in range(ob.item_count):
		if ob.get_item_text(i) == text:
			ob.select(i)
			return
	ob.select(0)


# ============================================================================
# Acciones CRUD desde la UI
# ============================================================================

func _new_enemy() -> void:
	# Prepara el formulario para un alta (sin ID seleccionado).
	selected_enemy_id = -1
	selected_enemy_index = -1
	_clear_form()


func _delete_enemy() -> void:
	# Borra el enemigo seleccionado por ID (si existe selección).
	if selected_enemy_id == -1:
		print("AdminEnemies: nada seleccionado para borrar")
		return

	repo.delete(selected_enemy_id)
	selected_enemy_id = -1

	_load_from_db()
	_apply_filter(search_edit.text)


func _save_enemy() -> void:
	# Construye el diccionario en formato BD a partir del formulario y guarda:
	# - create() si es nuevo (selected_enemy_id == -1)
	# - update() si ya existe
	var selected_idx := image_option.selected
	var image_path := ""
	if selected_idx >= 0 and selected_idx < _image_paths_by_index.size():
		image_path = _image_paths_by_index[selected_idx]

	var enemy := {
		"nombre": name_edit.text.strip_edges(),
		"descripcion": desc_edit.text.strip_edges(),
		"vida_base": int(hp_spin.value),
		"dano_base": int(dmg_spin.value),
		"recompensa_xp": 5, # Valor fijo provisional (cuando exista campo en UI, se mapeará aquí)
		"disponible": 1,
		"tipo": type_option.get_item_text(type_option.selected),
		"imagen": image_path,
	}

	# Validación mínima: no guardar enemigos sin nombre
	if enemy["nombre"] == "":
		print("AdminEnemies: nombre vacío, no guardo")
		return

	if selected_enemy_id == -1:
		repo.create(enemy)
		print("AdminEnemies: creado en BD")
	else:
		repo.update(selected_enemy_id, enemy)
		print("AdminEnemies: actualizado en BD")

	_load_from_db()
	_apply_filter(search_edit.text)


# ============================================================================
# Reset / limpieza de formulario
# ============================================================================

func _reset_form() -> void:
	# Si hay selección, recarga el enemigo actual; si no, deja el form limpio.
	if selected_enemy_index != -1:
		_fill_form(enemies[selected_enemy_index])
	else:
		_clear_form()


func _clear_form() -> void:
	# Valores por defecto para crear un enemigo nuevo.
	name_edit.text = ""
	type_option.select(0)
	hp_spin.value = 30
	dmg_spin.value = 5
	desc_edit.text = ""
	image_option.select(0)


# ============================================================================
# Navegación
# ============================================================================

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/admin/AdminHub.tscn")


# ============================================================================
# Código auxiliar / legado (no usado actualmente)
# ============================================================================
# Nota: Se mantiene por si lo reutilizas en fases tempranas o pruebas.
# Si quieres, en una siguiente pasada lo eliminamos para dejar el archivo “quirúrgico”.

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


func _next_id() -> int:
	var max_id := 0
	for e in enemies:
		max_id = maxi(max_id, int(e["id"]))
	return max_id + 1
