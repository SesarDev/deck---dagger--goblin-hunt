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

# Dummy shop items
var shop_items := [
	{"name":"Golpe", "cost":1, "desc":"Inflige 6 de daño.", "price":45},
	{"name":"Defensa", "cost":1, "desc":"Obtén 5 de bloque.", "price":40},
	{"name":"Cuchillada Goblin", "cost":2, "desc":"Inflige 10 de daño. Aplica 1 Vulnerable.", "price":65},
]

func _ready() -> void:
	gold_label.text = "Oro: %d" % gold
	btn_buy.disabled = true

	_fill_shop_cards()
	_connect_signals()

func _fill_shop_cards() -> void:
	(shop_card_1).set_card_data(shop_items[0].name, shop_items[0].cost, shop_items[0].desc)
	(shop_card_2).set_card_data(shop_items[1].name, shop_items[1].cost, shop_items[1].desc)
	(shop_card_3).set_card_data(shop_items[2].name, shop_items[2].cost, shop_items[2].desc)

func _connect_signals() -> void:
	shop_card_1.pressed.connect(func(): _select_item(0))
	shop_card_2.pressed.connect(func(): _select_item(1))
	shop_card_3.pressed.connect(func(): _select_item(2))

	btn_buy.pressed.connect(_buy_selected)
	btn_back.pressed.connect(_back_to_map)

func _select_item(i: int) -> void:
	selected_index = i
	var item = shop_items[i]

	detail_name.text = "Carta: %s" % item.name
	detail_cost.text = "Coste: %d" % item.cost
	detail_desc.text = item.desc
	detail_price.text = "Precio: %d oro" % item.price

	btn_buy.disabled = false

	print("Seleccionada carta tienda:", item.name)

func _buy_selected() -> void:
	if selected_index == -1:
		return

	var item = shop_items[selected_index]
	var price: int = item.price

	if gold < price:
		print("No hay oro suficiente")
		detail_price.text = "Precio: %d oro (NO DISPONIBLE)" % price
		return

	gold -= price
	gold_label.text = "Oro: %d" % gold

	print("Comprada:", item.name, "por", price)

	# Feedback visual simple
	detail_price.text = "Comprada por %d oro" % price
	btn_buy.disabled = true

func _back_to_map() -> void:
	get_tree().change_scene_to_file("res://src/scenes/map/MapScene.tscn")
