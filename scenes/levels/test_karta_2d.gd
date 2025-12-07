extends Node2D

@onready var PositionPlayer_1 = $PositionPlayer_1
@onready var PositionPlayer_2 = $PositionPlayer_2

var player_scene: PackedScene = preload("res://Narin_0/scenes/player.tscn")
var players: Dictionary = {}

func _ready() -> void:
	var my_id = multiplayer.get_unique_id()
	var is_host = multiplayer.is_server()
	
	print("🎮 Уровень загружен. ID: %d, Хост: %s" % [my_id, is_host])
	
	# Спавним себя
	_spawn_player_local(my_id)
	
	# Если я хост - спавню клиента
	if is_host:
		await get_tree().process_frame
		for player_id in NetworkManager.player_ids:
			if player_id != my_id:
				_spawn_player_local(player_id)

func _spawn_player_local(player_id: int) -> void:
	if players.has(player_id):
		return
	
	var is_host = multiplayer.is_server()
	var position_index = 1 if is_host and player_id == multiplayer.get_unique_id() else 2
	
	var player = player_scene.instantiate()
	player.name = "Player_%d" % player_id
	player.set_multiplayer_authority(player_id)
	player.global_position = PositionPlayer_1.global_position if position_index == 1 else PositionPlayer_2.global_position
	player.player_id = player_id
	
	add_child(player)
	players[player_id] = player
	
	print("✅ Спавнен игрок %d на позиции %d" % [player_id, position_index])
