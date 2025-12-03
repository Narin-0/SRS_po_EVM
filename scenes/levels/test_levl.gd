extends Node2D

@onready var PositionPlayer_1 = $PositionPlayer_1
@onready var PositionPlayer_2 = $PositionPlayer_2

func _ready() -> void:
	var my_id = get_tree().get_multiplayer().get_unique_id()
	
	# Спавним своего игрока на позиции 1
	var Player_1 = preload("res://Narin_0/scenes/player.tscn").instantiate()
	Player_1.set_name(str(my_id))
	Player_1.set_multiplayer_authority(my_id)
	Player_1.global_transform = PositionPlayer_1.global_transform
	add_child(Player_1)
	
	# Спавним другого игрока на позиции 2
	var other_id = Singleton.user_id
	if other_id != my_id:
		var Player_2 = preload("res://Narin_0/scenes/player.tscn").instantiate()
		Player_2.set_name(str(other_id))
		Player_2.set_multiplayer_authority(other_id)
		Player_2.global_transform = PositionPlayer_2.global_transform
		add_child(Player_2)
