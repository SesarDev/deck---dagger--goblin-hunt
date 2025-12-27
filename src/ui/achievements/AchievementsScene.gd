extends Control

@onready var btn_back: Button = %BtnBack
@onready var list_vbox: VBoxContainer = %ListVBox

@onready var detail_name: Label = %DetailName
@onready var detail_desc: RichTextLabel = %DetailDesc
@onready var detail_status: Label = %DetailStatus
@onready var detail_reward: Label = %DetailReward

const ITEM_SCENE := preload("res://src/ui/achievements/AchievementItem.tscn")

var achievements := []

func _ready() -> void:
	btn_back.pressed.connect(_back)

	_load_dummy()
	_rebuild_list()

func _load_dummy() -> void:
	achievements = [
		{"name":"Primer golpe", "short":"Juega tu primera carta de ataque.", "desc":"Has aprendido a atacar. Este es el primer paso para limpiar el bosque.", "reward":"Recompensa: +10 oro", "completed":true, "state":"Completado"},
		{"name":"Madera y sangre", "short":"Derrota a 3 goblins.", "desc":"Los goblins del poblado empiezan a temerte.", "reward":"Recompensa: Carta rara", "completed":false, "state":"Bloqueado"},
		{"name":"Mercader astuto", "short":"Compra 3 cartas en la tienda.", "desc":"Conoces el valor real del oro en territorio goblin.", "reward":"Recompensa: Descuento 5%", "completed":true, "state":"Completado"},
		{"name":"Superviviente", "short":"Termina una run sin morir.", "desc":"Sobrevives al bosque oscuro y regresas con historias que contar.", "reward":"Recompensa: Logro especial", "completed":false, "state":"Bloqueado"},
	]

func _rebuild_list() -> void:
	for c in list_vbox.get_children():
		c.queue_free()

	for a in achievements:
		var item = ITEM_SCENE.instantiate()
		list_vbox.add_child(item)
		item.set_data(a)
		item.pressed.connect(func(): _show_detail(a))

func _show_detail(a: Dictionary) -> void:
	detail_name.text = "Logro: %s" % a["name"]
	detail_desc.text = a["desc"]
	detail_status.text = "Estado: %s" % a["state"]
	detail_reward.text = a["reward"]

func _back() -> void:
	get_tree().change_scene_to_file("res://src/scenes/menu/MainMenu.tscn")
