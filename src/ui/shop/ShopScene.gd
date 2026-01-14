# res://src/ui/shop/ShopScene.gd
extends Control

@onready var shop_card_1 = %ShopCard_1
@onready var shop_card_2 = %ShopCard_2
@onready var shop_card_3 = %ShopCard_3

@onready var gold_label: Label = %GoldLabel

@onready var detail_name: Label = %DetailName
@onready var detail_cost: Label = %DetailCost
@onready var detail_desc: RichTextLabel = %DetailDesc
@onready var detail_price: Label = %DetailPrice

@onready var btn_back: Button = %BtnBackToMap
@onready var btn_buy: Button = %BtnBuy

var selected_index: int = -1
var gold: int = 120

# Items desde BD (id_carta, nombre, descripcion, coste_energia, rareza, price)
var shop_items: Array[Dictionary] = []

var progression := ProgressionService.new()
const USER_ID := 1


func _ready() -> void:
	gold_label.text = "Oro: %d" % gold
	btn_buy.disabled = true

	# Mantiene usuario_carta coherente para poder desbloquear al comprar
	progression.ensure_user_card_rows(USER_ID)

	_load_shop_from_db()
	_fill_shop_cards()
	_connect_signals()


func _load_shop_from_db() -> void:
	var rows := Database.query("""
		SELECT id_carta, nombre, descripcion, coste_energia, rareza
		FROM carta
		WHERE disponible = 1
		ORDER BY RANDOM()
		LIMIT 3;
	""")

	shop_items.clear()

	for r in rows:
		var item := {
			"id_carta": int(r.get("id_carta", -1)),
			"nombre": String(r.get("nombre", "")),
			"descripcion": String(r.get("descripcion", "")),
			"coste_energia": int(r.get("coste_energia", 0)),
			"rareza": String(r.get("rareza", "COMUN")),
		}
		item["price"] = _compute_price(item)
		shop_items.append(item)


func _compute_price(item: Dictionary) -> int:
	var base := 30 + int(item.get("coste_energia", 0)) * 10
	var rareza := String(item.get("rareza", "COMUN"))

	match rareza:
		"RARO":
			base += 15
		"EPICO":
			base += 35
		"LEGENDARIO":
			base += 60
		_:
			pass # COMUN

	return base


func _fill_shop_cards() -> void:
	if shop_items.size() < 3:
		push_error("Shop: no hay suficientes cartas en BD (mínimo 3 disponibles).")
		btn_buy.disabled = true
		return

	shop_card_1.set_card_data(shop_items[0]["nombre"], int(shop_items[0]["coste_energia"]), shop_items[0]["descripcion"])
	shop_card_2.set_card_data(shop_items[1]["nombre"], int(shop_items[1]["coste_energia"]), shop_items[1]["descripcion"])
	shop_card_3.set_card_data(shop_items[2]["nombre"], int(shop_items[2]["coste_energia"]), shop_items[2]["descripcion"])


func _connect_signals() -> void:
	shop_card_1.pressed.connect(func(): _select_item(0))
	shop_card_2.pressed.connect(func(): _select_item(1))
	shop_card_3.pressed.connect(func(): _select_item(2))

	btn_buy.pressed.connect(_buy_selected)
	btn_back.pressed.connect(_back_to_map)


func _select_item(i: int) -> void:
	selected_index = i
	var item: Dictionary = shop_items[i]

	detail_name.text = "Carta: %s" % item["nombre"]
	detail_cost.text = "Coste: %d" % int(item["coste_energia"])
	detail_desc.text = item["descripcion"]
	detail_price.text = "Precio: %d oro" % int(item["price"])

	btn_buy.disabled = false
	print("Seleccionada carta tienda:", item["nombre"])


func _buy_selected() -> void:
	if selected_index == -1:
		return

	var item: Dictionary = shop_items[selected_index]
	var price: int = int(item["price"])

	if gold < price:
		print("No hay oro suficiente")
		detail_price.text = "Precio: %d oro (NO DISPONIBLE)" % price
		return

	gold -= price
	gold_label.text = "Oro: %d" % gold

	print("Comprada:", item["nombre"], "por", price)

	# Persistir compra: desbloquear en usuario_carta (MVP)
	var id_carta := int(item.get("id_carta", -1))
	if id_carta > 0:
		Database.execute("""
			INSERT OR IGNORE INTO usuario_carta(id_usuario, id_carta, desbloqueada)
			VALUES (%d, %d, 0);
		""" % [USER_ID, id_carta])

		Database.execute("""
			UPDATE usuario_carta
			SET desbloqueada = 1
			WHERE id_usuario = %d AND id_carta = %d;
		""" % [USER_ID, id_carta])

	detail_price.text = "Comprada por %d oro" % price
	btn_buy.disabled = true


func _back_to_map() -> void:
	# 1) Marcar nodo shop como completado (desbloquea la siguiente columna)
	var cur_id := GameState.current_node_id
	GameState.cleared[cur_id] = true

	# 2) Persistencia (si tienes oro global, aquí actualizarías GameState.gold)
	# GameState.gold = gold

	GameState.save_to_disk()
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
