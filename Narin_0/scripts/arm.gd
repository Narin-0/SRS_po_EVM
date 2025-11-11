extends Node2D

func _process(_delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position
	if dir.length() > 0.001:
		rotation = dir.angle()
