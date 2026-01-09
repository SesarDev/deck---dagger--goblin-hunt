extends Control

@onready var anim: AnimationPlayer = $AnimationPlayer
@export var next_scene := "res://src/scenes/menu/MainMenu.tscn"

func _ready():
	anim.play("fade_in")
	await anim.animation_finished

	await get_tree().create_timer(1.5).timeout

	anim.play("fade_out")
	await anim.animation_finished

	get_tree().change_scene_to_file(next_scene)
