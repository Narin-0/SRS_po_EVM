extends Node2D

@onready var host_button = $"Host Button"
@onready var join_button = $"Join Button"

var network_manager: Node

func _ready() -> void:
	network_manager = get_node("/root/Singleton")
	
	if not network_manager:
		push_error("❌ Singleton не найден!")
		return
	
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.connection_failed.connect(_on_connection_failed)
	
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	print("✅ Menu инициализировано")

func _on_host_pressed() -> void:
	print("🖥️ Кнопка Host нажата")
	host_button.disabled = true
	join_button.disabled = true
	network_manager.host_game()
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/test_levl.tscn")

func _on_join_pressed() -> void:
	print("🎮 Кнопка Join нажата")
	host_button.disabled = true
	join_button.disabled = true
	network_manager.join_game("127.0.0.1")
	await network_manager.multiplayer.connected_to_server
	print("✅ Успешно подключено!")
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/test_levl.tscn")

func _on_player_connected(peer_id: int) -> void:
	print("✅ Игрок подключен: %d" % peer_id)

func _on_connection_failed() -> void:
	print("❌ Ошибка подключения")
	host_button.disabled = false
	join_button.disabled = false
