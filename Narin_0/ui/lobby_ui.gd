extends Control

@onready var host_btn = $VBoxContainer/HostButton
@onready var join_btn = $VBoxContainer/JoinButton
@onready var ip_input = $VBoxContainer/IPInput
@onready var status_label = $VBoxContainer/StatusLabel

var network_manager: Node


func _ready() -> void:
	network_manager = get_tree().root.get_node_or_null("NetworkManager")
	
	if not network_manager:
		push_error("NetworkManager не найден!")
		return
	
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.connection_failed.connect(_on_connection_failed)


func _on_host_pressed() -> void:
	network_manager.host_game()
	status_label.text = "🖥️ Вы хост сервера"
	_disable_buttons()


func _on_join_pressed() -> void:
	var ip = ip_input.text
	if ip.is_empty():
		status_label.text = "⚠️ Введите IP адрес"
		return
	
	network_manager.join_game(ip)
	status_label.text = "🔄 Подключение к %s..." % ip
	_disable_buttons()


func _on_player_connected(peer_id: int) -> void:
	status_label.text = "✅ Игрок %d подключен!" % peer_id
	
	if network_manager.get_players_count() >= 2:
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/multiplayer_level.tscn")


func _on_connection_failed() -> void:
	status_label.text = "❌ Ошибка подключения"
	_enable_buttons()


func _disable_buttons() -> void:
	host_btn.disabled = true
	join_btn.disabled = true
	ip_input.editable = false


func _enable_buttons() -> void:
	host_btn.disabled = false
	join_btn.disabled = false
	ip_input.editable = true
