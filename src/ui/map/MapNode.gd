extends Button
class_name MapNode

enum NodeType { NORMAL, ELITE, BOSS, SHOP, EVENT }

@export var node_type: NodeType = NodeType.NORMAL : set = set_node_type

# Asigna estas texturas desde el Inspector (en el MapNode.tscn)
@export var icon_normal: Texture2D
@export var icon_elite: Texture2D
@export var icon_boss: Texture2D
@export var icon_shop: Texture2D
@export var icon_event: Texture2D

# Estado (para el objetivo 2, pero lo dejamos preparado)
var locked: bool = false : set = set_locked
var cleared: bool = false : set = set_cleared

func _ready() -> void:
	# El mapa suele ir mejor solo con icono, sin texto.
	text = ""
	_update_visual()

func set_node_type(value: NodeType) -> void:
	node_type = value
	_update_visual()

func set_locked(value: bool) -> void:
	locked = value
	disabled = locked
	_update_visual()

func set_cleared(value: bool) -> void:
	cleared = value
	_update_visual()

func _update_visual() -> void:
	# Icono según tipo
	icon = _get_icon_for_type(node_type)

	# Apariencia (simple, sin tocar Theme global)
	if locked:
		modulate = Color(1, 1, 1, 0.35)
	elif cleared:
		modulate = Color(0.75, 0.75, 0.75, 1.0)
	else:
		modulate = Color(1, 1, 1, 1.0)

func _get_icon_for_type(t: NodeType) -> Texture2D:
	match t:
		NodeType.NORMAL: return icon_normal
		NodeType.ELITE:  return icon_elite
		NodeType.BOSS:   return icon_boss
		NodeType.SHOP:   return icon_shop
		NodeType.EVENT:  return icon_event
		_:               return icon_normal
