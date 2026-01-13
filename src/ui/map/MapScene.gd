extends Control

@onready var btn_menu: Button = %BtnMenu

@onready var hbox_floors: HBoxContainer = %HBoxFloors
@onready var line_layer: Node2D = %LineLayer

@export var map_node_scene: PackedScene

@export_range(2, 4) var min_nodes_per_column := 2
@export_range(2, 4) var max_nodes_per_column := 4

@export_range(1, 3) var min_choices := 1
@export_range(1, 3) var max_choices := 3

@export var columns := 8

# -----------------------------
# Probabilidades de tipos (cols 2..columns-1)
# -----------------------------
@export_range(0.0, 1.0) var p_event := 0.25
@export_range(0.0, 1.0) var p_shop := 0.15
@export_range(0.0, 1.0) var p_elite := 0.12
# NORMAL = el resto

@export var elite_min_col := 5
@export var shop_min_col := 3
@export var forbid_shop_col_before_boss := true   # evita tienda en col columns-1
@export var forbid_consecutive_shops := true

# -----------------------------
# Estado del mapa
# -----------------------------
var nodes_by_column: Array = []   # index 1..columns -> Array[String]
var nodes_by_id: Dictionary = {}                 # "col-row" -> MapNode
var adjacency: Dictionary = {}                   # "col-row" -> Array["col-row"]
var connections: Array = []                      # pares [from_node, to_node] para dibujar líneas

var current_node_id: String = "1-1"
var cleared: Dictionary = {}                     # "col-row" -> bool


func _ready() -> void:
	if map_node_scene == null:
		push_error("MapScene: asigna map_node_scene (MapNode.tscn)")
		return

	btn_menu.pressed.connect(_on_btn_menu_pressed)

	if GameState.run_active and not GameState.adjacency.is_empty():
		_restore_map_from_state()
	else:
		_generate_new_map_and_save_state()

	_draw_connections()
	_connect_node_signals()

	# Estado inicial / restaurado
	current_node_id = GameState.current_node_id
	cleared = GameState.cleared.duplicate(true)

	_apply_cleared_to_nodes()
	_set_all_locked(true)
	_set_locked(current_node_id, false)
	_refresh_unlocks_from_current()


# ------------------------------------------------------
# Construcción de columnas + nodos (1 / 2-4 / 1)
# ------------------------------------------------------
func _build_columns_nodes_dynamic_counts(generate_and_store: bool) -> void:
	nodes_by_id.clear()
	nodes_by_column.clear()
	connections.clear()
	adjacency.clear()

	# Limpia columnas
	for child in hbox_floors.get_children():
		if child is VBoxContainer:
			for n in child.get_children():
				n.queue_free()

	nodes_by_column.resize(columns + 1)
	for c in range(1, columns + 1):
		nodes_by_column[c] = []

	# Calcula count por columna
	for col in range(1, columns + 1):
		var count := 1
		if col != 1 and col != columns:
			if generate_and_store:
				count = randi_range(min_nodes_per_column, max_nodes_per_column)
				GameState.nodes_per_column[col] = count
			else:
				count = int(GameState.nodes_per_column.get(col, 2))
		else:
			if generate_and_store:
				GameState.nodes_per_column[col] = 1

		var vbox := _get_vbox_for_column(col)

		for row in range(1, count + 1):
			var node: MapNode = map_node_scene.instantiate()
			node.name = "Node_%d_%d" % [col, row]
			vbox.add_child(node)

			if col == columns:
				node.node_type = MapNode.NodeType.BOSS

			var id := "%d-%d" % [col, row]
			nodes_by_id[id] = node
			nodes_by_column[col].append(id)


func _assign_node_types_by_probability() -> void:
	# Col 1: inicio siempre NORMAL
	_set_column_types_fixed(1, MapNode.NodeType.NORMAL)

	# Col final: boss
	_set_column_types_fixed(columns, MapNode.NodeType.BOSS)

	# Columnas intermedias
	var prev_col_had_shop := false

	for col in range(2, columns):
		var ids: Array = nodes_by_column[col]

		# Restricciones por columna
		var allow_elite := col >= elite_min_col
		var allow_shop := col >= shop_min_col
		if forbid_shop_col_before_boss and col == columns - 1:
			allow_shop = false
		if forbid_consecutive_shops and prev_col_had_shop:
			allow_shop = false

		# Asignación inicial por nodo
		var col_has_shop := false
		var col_has_combat := false

		for id_any in ids:
			var id: String = id_any as String
			var n: MapNode = nodes_by_id[id]

			var t := _roll_node_type(allow_shop, allow_elite)
			n.node_type = t

			if t == MapNode.NodeType.SHOP:
				col_has_shop = true
			if t == MapNode.NodeType.NORMAL or t == MapNode.NodeType.ELITE:
				col_has_combat = true

		# Regla: en cada columna debe existir al menos 1 combate (normal o élite)
		if not col_has_combat and ids.size() > 0:
			var pick_id: String = ids.pick_random() as String
			nodes_by_id[pick_id].node_type = MapNode.NodeType.NORMAL
			col_has_combat = true

		prev_col_had_shop = col_has_shop


func _set_column_types_fixed(col: int, t: int) -> void:
	var ids: Array = nodes_by_column[col]
	for id_any in ids:
		var id: String = id_any as String
		var n: MapNode = nodes_by_id[id]
		n.node_type = t


func _roll_node_type(allow_shop: bool, allow_elite: bool) -> int:
	var r := randf()

	# EVENT
	if r < p_event:
		return MapNode.NodeType.EVENT
	r -= p_event

	# SHOP
	if allow_shop:
		if r < p_shop:
			return MapNode.NodeType.SHOP
		r -= p_shop

	# ELITE
	if allow_elite:
		if r < p_elite:
			return MapNode.NodeType.ELITE
		r -= p_elite

	return MapNode.NodeType.NORMAL


func _get_vbox_for_column(col: int) -> VBoxContainer:
	var path := "VBoxFloor%d" % col
	var vbox := hbox_floors.get_node_or_null(path)
	if vbox == null:
		push_error("MapScene: falta el nodo %s dentro de HBoxFloors." % path)
		return VBoxContainer.new()
	return vbox as VBoxContainer


# ------------------------------------------------------
# Conexiones aleatorias por partida (1-3 salidas)
# Garantiza: todos alcanzables y boss alcanzable siempre
# ------------------------------------------------------
func _generate_connections_random() -> void:
	adjacency.clear()
	connections.clear()

	# init adjacency keys
	for id_any in nodes_by_id.keys():
		var id: String = id_any as String
		adjacency[id] = []

	# 1) Para cada nodo de col 1..(columns-1), crea 1..3 salidas hacia col+1
	for col in range(1, columns):
		var from_ids: Array = nodes_by_column[col]
		var to_ids: Array = nodes_by_column[col + 1]

		for from_id_any in from_ids:
			var from_id: String = from_id_any as String

			var choices := randi_range(min_choices, max_choices)
			choices = clamp(choices, 1, to_ids.size())

			var picked := _pick_unique(to_ids, choices)
			for to_id_any in picked:
				var to_id: String = to_id_any as String
				_add_edge(from_id, to_id)

	# 2) Garantiza que cada nodo de col 2..columns tenga al menos 1 entrada desde col-1
	for col in range(2, columns + 1):
		var to_ids: Array = nodes_by_column[col]
		var from_ids: Array = nodes_by_column[col - 1]

		for to_id_any in to_ids:
			var to_id: String = to_id_any as String
			if _in_degree(to_id) == 0:
				var from_id: String = from_ids[randi_range(0, from_ids.size() - 1)] as String
				_add_edge(from_id, to_id)

	# 3) Refuerzo opcional: el boss con entradas extra (si hay suficientes nodos previos)
	var boss_id: String = nodes_by_column[columns][0] as String
	var last_from: Array = nodes_by_column[columns - 1]
	var extra: int = min(2, last_from.size())

	for i in range(extra):
		var from_id: String = last_from[i] as String
		_add_edge(from_id, boss_id)


func _add_edge(from_id: String, to_id: String) -> void:
	if to_id in adjacency[from_id]:
		return

	if _col_from_id(to_id) <= _col_from_id(from_id):
		return

	adjacency[from_id].append(to_id)

	var from_node: Node = nodes_by_id[from_id]
	var to_node: Node = nodes_by_id[to_id]
	connections.append([from_node, to_node])


func _in_degree(id: String) -> int:
	var count := 0
	for k_any in adjacency.keys():
		var k: String = k_any as String
		if id in adjacency[k]:
			count += 1
	return count


func _pick_unique(source: Array, amount: int) -> Array:
	var tmp := source.duplicate()
	tmp.shuffle()
	return tmp.slice(0, amount)


# ------------------------------------------------------
# Señales y click (abre escena directo)
# ------------------------------------------------------
func _connect_node_signals() -> void:
	for id_any in nodes_by_id.keys():
		var id: String = id_any as String
		var n: MapNode = nodes_by_id[id]
		n.pressed.connect(func(): _on_node_pressed(id))


func _on_node_pressed(id: String) -> void:
	var cur_id := GameState.current_node_id
	var node: MapNode = nodes_by_id[id]

	# Si es el nodo actual, solo bloqueamos si YA está completado
	if id == cur_id and bool(GameState.cleared.get(cur_id, false)):
		return

	# No permitir clicks en bloqueados
	if node.disabled:
		return

	# Solo vecino directo desde el nodo actual
	if id != cur_id:
		var next_ids: Array = adjacency.get(cur_id, [])
		if not (id in next_ids):
			return

	# Avanza
	GameState.current_node_id = id
	current_node_id = id

	_refresh_unlocks_from_current()

	match node.node_type:
		MapNode.NodeType.SHOP:
			get_tree().change_scene_to_file("res://src/scenes/shop/ShopScene.tscn")
		MapNode.NodeType.EVENT:
			get_tree().change_scene_to_file("res://src/scenes/events/EventScene.tscn")
		_:
			get_tree().change_scene_to_file("res://src/scenes/combat/CombatScene.tscn")


# Llamar al volver de combate/tienda/evento
func complete_current_node() -> void:
	var cur_id := GameState.current_node_id
	GameState.cleared[cur_id] = true
	current_node_id = cur_id
	_apply_cleared_to_nodes()
	_refresh_unlocks_from_current()


func _apply_cleared_to_nodes() -> void:
	for id in nodes_by_id.keys():
		var done := bool(GameState.cleared.get(id, false))
		nodes_by_id[id].cleared = done


func _deep_copy_adjacency(src: Dictionary) -> Dictionary:
	var dst: Dictionary = {}
	for k in src.keys():
		var arr: Array = src[k]
		dst[k] = arr.duplicate(true)
	return dst


# ------------------------------------------------------
# Progresión: desbloquear alcanzables a la derecha
# ------------------------------------------------------
func _refresh_unlocks_from_current() -> void:
	var cur_id := GameState.current_node_id

	_set_all_locked(true)

	# El nodo actual siempre visible/clicable (para poder entrar por primera vez)
	nodes_by_id[cur_id].locked = false

	# Si el nodo actual NO está completado, NO se desbloquea nada a la derecha
	if not bool(GameState.cleared.get(cur_id, false)):
		return

	# Si está completado, desbloquea vecinos directos
	var next_ids: Array = adjacency.get(cur_id, [])
	for nxt_id in next_ids:
		nodes_by_id[nxt_id].locked = false


# ------------------------------------------------------
# Estado visual del nodo
# ------------------------------------------------------
func _set_all_locked(value: bool) -> void:
	for id_any in nodes_by_id.keys():
		var id: String = id_any as String
		_set_locked(id, value)


func _set_locked(id: String, value: bool) -> void:
	var n: MapNode = nodes_by_id[id]
	n.locked = value


func _set_cleared(id: String, value: bool) -> void:
	var n: MapNode = nodes_by_id[id]
	n.cleared = value


# ------------------------------------------------------
# Dibujo de líneas
# ------------------------------------------------------
func _draw_connections() -> void:
	await get_tree().process_frame

	for c in line_layer.get_children():
		c.queue_free()

	for pair in connections:
		var from_node: Node = pair[0]
		var to_node: Node = pair[1]

		var line := Line2D.new()
		line.default_color = Color(0.84, 0.76, 0.62)
		line.width = 6
		line_layer.add_child(line)

		var p1 = from_node.get_global_position() + from_node.size / 2
		var p2 = to_node.get_global_position() + to_node.size / 2

		line.add_point(p1)
		line.add_point(p2)


# ------------------------------------------------------
# Helpers IDs
# ------------------------------------------------------
func _col_from_id(id: String) -> int:
	return int(id.split("-")[0])


# GENERAR Y GUARDAR
func _generate_new_map_and_save_state() -> void:
	# Seed estable para toda la run
	var run_seed: int = int(Time.get_unix_time_from_system()) ^ randi()

	GameState.new_run(run_seed, columns)
	seed(run_seed) # fija RNG para que todo sea determinista durante la creación

	_build_columns_nodes_dynamic_counts(true)
	_assign_node_types_by_probability()
	_generate_connections_random()

	# Persistimos snapshot completo
	GameState.current_node_id = "1-1"
	GameState.cleared.clear()
	for id in nodes_by_id.keys():
		GameState.cleared[id] = false

	GameState.node_types.clear()
	for id in nodes_by_id.keys():
		GameState.node_types[id] = int(nodes_by_id[id].node_type)

	GameState.adjacency = _deep_copy_adjacency(adjacency)

	# Elegir 1 jefe para esta run y guardarlo en GameState (si aún no hay uno)
	# AJUSTE: la tabla probablemente es "enemigo" (singular). Cambia si en tu BD es "enemigos".
	if GameState.boss_enemy_id <= 0:
		var boss_rows := Database.query("SELECT id_enemigo FROM enemigo WHERE tipo = 'Jefe' ORDER BY RANDOM() LIMIT 1;")
		if boss_rows.size() > 0:
			GameState.boss_enemy_id = int(boss_rows[0]["id_enemigo"])
		else:
			GameState.boss_enemy_id = -1

	# Guarda inmediatamente el snapshot, incluido boss_enemy_id
	GameState.save_to_disk()


func _restore_map_from_state() -> void:
	columns = GameState.map_columns

	_build_columns_nodes_dynamic_counts(false)

	# Aplica tipos guardados
	for id in nodes_by_id.keys():
		if GameState.node_types.has(id):
			nodes_by_id[id].node_type = GameState.node_types[id]

	# Restaura adjacency y reconstruye conexiones
	adjacency = _deep_copy_adjacency(GameState.adjacency)
	connections.clear()

	for from_id in adjacency.keys():
		var tos: Array = adjacency[from_id]
		for to_id in tos:
			if nodes_by_id.has(from_id) and nodes_by_id.has(to_id):
				connections.append([nodes_by_id[from_id], nodes_by_id[to_id]])

	current_node_id = GameState.current_node_id


func _on_btn_menu_pressed() -> void:
	print("boton menu pulsado")
	GameState.save_to_disk()
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")


func _save_game() -> void:
	GameState.save_to_disk()
