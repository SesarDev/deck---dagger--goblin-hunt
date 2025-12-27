extends Button

@onready var lbl_name: Label = $VBox/CardName
@onready var lbl_cost: Label = $VBox/CardCost
@onready var lbl_desc: Label = $VBox/CardDescription

func set_card_data(name: String, cost: int, description: String) -> void:
	lbl_name.text = name
	lbl_cost.text = "Coste: %d" % cost
	lbl_desc.text = description
