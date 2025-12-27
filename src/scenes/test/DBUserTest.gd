extends Node

func _ready() -> void:
	print("=== DB User Test ===")

	# 1. Crear un usuario PLAYER
	DB.create_user("player_test", "PLAYER")

	# 2. Crear un usuario ADMIN
	DB.create_user("admin_test", "ADMIN")

	# 3. Leer todos los usuarios
	var users = DB.get_all_users()
	print("Users in DB:")
	for u in users:
		print(" - id:%s | %s | role:%s" % [u.id, u.username, u.role])

	# 4. Promocionar player_test a ADMIN (ejemplo de UPDATE)
	if users.size() > 0:
		var first_user_id = int(users[0].id)
		DB.update_user_role(first_user_id, "ADMIN")
		print("Updated role of user id %s to ADMIN" % first_user_id)

	# 5. Borrar un usuario (ejemplo de DELETE)
	if users.size() > 1:
		var second_user_id = int(users[1].id)
		DB.delete_user(second_user_id)
		print("Deleted user id %s" % second_user_id)

	# 6. Volver a listar para ver cambios
	var final_users = DB.get_all_users()
	print("Final users:")
	for u in final_users:
		print(" - id:%s | %s | role:%s" % [u.id, u.username, u.role])

	print("=== End DB User Test ===")
