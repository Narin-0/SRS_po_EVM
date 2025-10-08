extends CharacterBody2D

var max_speet = 80

func _process(delta):
	var direction = get_direction_to_player()
	velocity = max_speet * direction
	move_and_slide()

func get_direction_to_player():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		return (player.global_position - global_position).normalized()
	return Vector2(0,0)
