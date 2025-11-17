extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_failed

const PORT = 9999
const MAX_PLAYERS = 4

var peer: ENetMultiplayerPeer


func _ready() -> void:
	print("🌐 NetworkManager инициализирован")
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func host_game() -> void:
	print("🖥️ Попытка создать сервер на порту %d..." % PORT)
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	
	if error:
		print("❌ Ошибка создания сервера: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("✅ Сервер успешно создан на порту %d" % PORT)
	print("📊 Мой ID: %d" % multiplayer.get_unique_id())


func join_game(ip: String, port: int = PORT) -> void:
	print("🔄 Попытка подключиться к %s:%d..." % [ip, port])
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	
	if error:
		print("❌ Ошибка подключения: ", error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("⏳ Подключение инициировано к %s:%d" % [ip, port])


func _on_connected_to_server() -> void:
	print("✅ Успешно подключено к серверу!")
	print("📊 Мой ID: %d" % multiplayer.get_unique_id())


func _on_server_disconnected() -> void:
	print("❌ Отключено от сервера")


func _on_peer_connected(peer_id: int) -> void:
	print("🎮 Новый игрок подключен: ID=%d" % peer_id)
	print("📊 Всего игроков: %d" % (multiplayer.get_peers().size() + 1))
	player_connected.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("👋 Игрок отключен: ID=%d" % peer_id)
	print("📊 Осталось игроков: %d" % (multiplayer.get_peers().size() + 1))
	player_disconnected.emit(peer_id)


func get_players_count() -> int:
	return multiplayer.get_peers().size() + 1
