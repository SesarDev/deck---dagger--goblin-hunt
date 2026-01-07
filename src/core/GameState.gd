extends Node

# Identifica si hay partida en curso
var run_active: bool = false

# RNG estable para que no cambie nada entre cargas (alternativa al snapshot completo)
var map_seed: int = 0

# Estado persistente del mapa
var map_columns: int = 8
var nodes_per_column: Dictionary = {}  # col(int) -> count(int)

# Tipos por nodo: "col-row" -> int (MapNode.NodeType)
var node_types: Dictionary = {}

# Grafo: "col-row" -> Array[String] vecinos
var adjacency: Dictionary = {}

# Progresión
var current_node_id: String = "1-1"
var cleared: Dictionary = {}           # "col-row" -> bool

func new_run(seed: int, columns: int) -> void:
	run_active = true
	map_seed = seed
	map_columns = columns

	nodes_per_column.clear()
	node_types.clear()
	adjacency.clear()
	cleared.clear()
	current_node_id = "1-1"

func clear_run() -> void:
	run_active = false
	nodes_per_column.clear()
	node_types.clear()
	adjacency.clear()
	cleared.clear()
	current_node_id = "1-1"

const SAVE_PATH := "user://savegame.json"

func save_to_disk() -> void:
	var data := {
		"run_active": run_active,
		"map_columns": map_columns,
		"nodes_per_column": nodes_per_column,
		"node_types": node_types,
		"adjacency": adjacency,
		"cleared": cleared,
		"current_node_id": current_node_id
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar la partida")
		return

	file.store_string(JSON.stringify(data))
	file.close()

func load_from_disk() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir el save")
		return false

	var text: String = file.get_as_text()
	file.close()

	if text.strip_edges().is_empty():
		push_error("Save vacío")
		return false

	var json: JSON = JSON.new()
	var err: int = json.parse(text)
	if err != OK:
		push_error("JSON error línea %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false

	var data: Dictionary = json.data   # 🔴 ESTA ES LA CLAVE
	# nada de := aquí

	run_active = bool(data.get("run_active", false))
	map_columns = int(data.get("map_columns", 8))
	# Normaliza nodes_per_column para que las claves sean int (JSON las carga como String)
	var npc_raw: Dictionary = data.get("nodes_per_column", {})
	nodes_per_column = {}
	for k in npc_raw.keys():
		nodes_per_column[int(k)] = int(npc_raw[k])

	node_types = data.get("node_types", {})
	adjacency = data.get("adjacency", {})
	cleared = data.get("cleared", {})
	current_node_id = String(data.get("current_node_id", "1-1"))

	return run_active
