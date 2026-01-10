extends RefCounted
class_name EnemyCombatState

var id_enemigo: int = -1
var name: String = "Enemigo"
var hp: int = 1
var max_hp: int = 1
var damage: int = 0
var recompensa_xp: int = 0
var tipo: String = "NORMAL"
var imagen: String = ""


func load_from_row(row: Dictionary) -> void:
	id_enemigo = int(row["id_enemigo"])
	name = String(row["nombre"])
	max_hp = int(row["vida_base"])
	hp = max_hp
	damage = int(row["dano_base"])
	recompensa_xp = int(row.get("recompensa_xp", 0))
	tipo = String(row.get("tipo", "NORMAL"))
	imagen = String(row.get("imagen", ""))
