extends RefCounted
class_name PlayerCombatState

var max_hp: int = 50
var hp: int = 50
var block: int = 0

var energy_max: int = 3
var energy: int = 3
var draw_per_turn: int = 5

var deck: Array[Dictionary] = []
var hand: Array[Dictionary] = []
var discard: Array[Dictionary] = []

func reset_for_new_turn() -> void:
	block = 0
	energy = energy_max
