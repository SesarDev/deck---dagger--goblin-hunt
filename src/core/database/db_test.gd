extends Node

func _ready() -> void:
	print(Database.query("SELECT id_usuario, nombre_usuario, rol FROM usuario ORDER BY id_usuario;"))
	print(Database.query("SELECT id_carta, nombre, tipo, coste_energia, valor_base FROM carta ORDER BY id_carta LIMIT 5;"))
	print(Database.query("SELECT id_enemigo, nombre, vida_base, dano_base FROM enemigo ORDER BY id_enemigo;"))
