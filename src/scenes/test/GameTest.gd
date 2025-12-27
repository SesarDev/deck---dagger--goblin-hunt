extends Node

func _ready() -> void:
	print("=== Game Test ===")

	# Forzamos login con un usuario concreto (para ver que funciona)
	Game.login_or_register("andres_player", false)
	print("Is admin?", Game.is_admin())

	# Crear una run
	Game.start_run()

	# Simular final de partida
	Game.end_run("LOSS", 3, "")

	# Probar stats
	Game.add_stat("total_damage", "150")
	Game.add_stat("goblins_killed", "12")

	var stats = Game.get_stats()
	print("Stats for current user:")
	for s in stats:
		print(" - ", s.key, " = ", s.value)

	print("=== End Game Test ===")
