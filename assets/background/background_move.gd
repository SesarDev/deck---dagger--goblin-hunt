extends TextureRect

func _process(delta):
	rotation = sin(Time.get_ticks_msec() * 0.0001) * 0.002
