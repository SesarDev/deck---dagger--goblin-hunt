extends Control

@onready var node_1_1 = %Node_1_1
@onready var node_2_1 = %Node_2_1
@onready var node_2_2 = %Node_2_2
@onready var node_3_1 = %Node_3_1
@onready var node_4_1 = %Node_4_1
@onready var node_4_2 = %Node_4_2
@onready var node_5_1 = %Node_5_1
@onready var line_layer = $LineLayer
var connections: Array = []

func _ready():
	# Por ahora solo prints para pruebas
	node_1_1.pressed.connect(func(): _select_node("1-1"))
	node_2_1.pressed.connect(func(): _select_node("2-1"))
	node_2_2.pressed.connect(func(): _select_node("2-2"))
	node_3_1.pressed.connect(func(): _select_node("3-1"))
	node_4_1.pressed.connect(func(): _select_node("4-1"))
	node_4_2.pressed.connect(func(): _select_node("4-2"))
	node_5_1.pressed.connect(func(): _select_node("5-1 (Boss)"))
	_connect_nodes()
	_draw_connections()

func _select_node(id: String) -> void:
	print("Nodo seleccionado:", id)

	if id == "2-2" or id == "4-2":
		get_tree().change_scene_to_file("res://src/scenes/events/EventScene.tscn")
	elif id == "3-1":
		get_tree().change_scene_to_file("res://src/scenes/shop/ShopScene.tscn")
	else:
		get_tree().change_scene_to_file("res://src/scenes/combat/CombatScene.tscn")


func _connect_nodes():
	# Aquí definimos qué nodos conectan con cuáles
	# Cada conexión será un diccionario o par de nodos
	connections = [
		[%Node_1_1, %Node_2_1],
		[%Node_1_1, %Node_2_2],
		[%Node_2_1, %Node_3_1],
		[%Node_2_2, %Node_3_1],
		[%Node_3_1, %Node_4_1],
		[%Node_3_1, %Node_4_2],
		[%Node_4_1, %Node_5_1],
		[%Node_4_2, %Node_5_1],
	]

func _draw_connections():
	await get_tree().process_frame
	for pair in connections:
		var from_node: Node = pair[0]
		var to_node: Node = pair[1]

		# Crear línea nueva
		var line := Line2D.new()
		line.default_color = Color(0.84, 0.76, 0.62) # beige madera
		line.width = 6

		line_layer.add_child(line)

		# Posiciones globales
		var p1 = from_node.get_global_position() + from_node.size / 2
		var p2 = to_node.get_global_position() + to_node.size / 2

		line.add_point(p1)
		line.add_point(p2)
