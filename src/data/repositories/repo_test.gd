extends Node

func _ready() -> void:
	var cards := CardRepository.new().get_all()
	print("[Cards]", cards.size(), cards[0] if cards.size() > 0 else "no cards")

	var enemies := EnemyRepository.new().get_all()
	print("[Enemies]", enemies.size(), enemies[0] if enemies.size() > 0 else "no enemies")
