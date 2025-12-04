extends Node

signal player_connected
signal player_disconnected  
signal game_started
signal connection_failed
signal connection_succeeded

const PORT = 9999
const MAX_PLAYERS = 4

var peer: ENetMultiplayerPeer
var is_host: bool = false
var player_ids: Array = []

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("🌐 NetworkManager готов. Порт: ", PORT)

func host_game() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🖥️ СОЗДАНИЕ СЕРВЕРА...")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	
	if error != OK:
		print("❌ ОШИБКА создания сервера!")
		print("   Код ошибки: ", error)
		print("   Возможные причины:")
		print("   - Порт ", PORT, " уже занят")
		print("   - Недостаточно прав")
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	is_host = true
	var my_id = multiplayer.get_unique_id()
	player_ids.append(my_id)
	
	print("✅ СЕРВЕР СОЗДАН!")
	print("   Мой ID: ", my_id)
	print("   Порт: ", PORT)
	print("   Макс. игроков: ", MAX_PLAYERS)
	print("   Список игроков: ", player_ids)
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	player_connected.emit()

func join_game(ip: String) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🔌 ПОДКЛЮЧЕНИЕ К СЕРВЕРУ...")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   IP: ", ip)
	print("   Порт: ", PORT)
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
	
	if error != OK:
		print("❌ ОШИБКА подключения!")
		print("   Код ошибки: ", error)
		print("   Возможные причины:")
		print("   - Сервер не запущен")
		print("   - Неверный IP: ", ip)
		print("   - Порт ", PORT, " недоступен")
		print("   - Файрвол блокирует")
		print("━━━━━━━━━━━━━━━━━━━━━━━━")
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("⏳ Ожидание ответа от сервера...")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")

func _on_peer_connected(id: int) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🔗 ИГРОК ПОДКЛЮЧИЛСЯ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   ID игрока: ", id)
	print("   Я хост: ", is_host)
	print("   Текущий список: ", player_ids)
	
	if is_host:
		player_ids.append(id)
		print("   ✅ Игрок добавлен")
		print("   📋 Новый список: ", player_ids)
		print("   📤 Отправляю список клиенту ", id)
		
		# Даём небольшую задержку для стабильности
		await get_tree().create_timer(0.1).timeout
		
		rpc_id(id, "receive_player_list", player_ids)
		rpc("notify_player_joined", id)
		
		print("   ✅ Данные отправлены")
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	player_connected.emit()

func _on_peer_disconnected(id: int) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("👋 ИГРОК ОТКЛЮЧИЛСЯ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   ID игрока: ", id)
	print("   До отключения: ", player_ids)
	
	player_ids.erase(id)
	
	print("   После отключения: ", player_ids)
	
	if is_host:
		rpc("notify_player_left", id)
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	player_disconnected.emit()

func _on_connected_to_server() -> void:
	var my_id = multiplayer.get_unique_id()
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("✅ ПОДКЛЮЧЕНО К СЕРВЕРУ!")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   Мой ID: ", my_id)
	print("   Ожидаю список игроков от сервера...")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("❌ НЕ УДАЛОСЬ ПОДКЛЮЧИТЬСЯ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   Проверьте:")
	print("   1. Сервер запущен?")
	print("   2. IP правильный?")
	print("   3. Порт ", PORT, " открыт?")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("❌ СЕРВЕР ОТКЛЮЧИЛСЯ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	player_ids.clear()
	is_host = false

@rpc("any_peer", "call_remote", "reliable")
func receive_player_list(ids: Array) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("📥 ПОЛУЧЕН СПИСОК ИГРОКОВ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   Список: ", ids)
	print("   Всего игроков: ", ids.size())
	
	player_ids = ids.duplicate()
	
	var my_id = multiplayer.get_unique_id()
	print("   Мой ID: ", my_id)
	print("   Я в списке: ", player_ids.has(my_id))
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	player_connected.emit()

@rpc("any_peer", "call_remote", "reliable")
func notify_player_joined(id: int) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("➕ НОВЫЙ ИГРОК")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   ID: ", id)
	print("   До: ", player_ids)
	
	if not player_ids.has(id):
		player_ids.append(id)
		print("   ✅ Добавлен")
	else:
		print("   ⚠️ Уже в списке")
	
	print("   После: ", player_ids)
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	player_connected.emit()

@rpc("any_peer", "call_remote", "reliable")
func notify_player_left(id: int) -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("➖ ИГРОК ПОКИНУЛ ИГРУ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   ID: ", id)
	print("   До: ", player_ids)
	
	player_ids.erase(id)
	
	print("   После: ", player_ids)
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	player_disconnected.emit()

@rpc("any_peer", "call_local", "reliable")
func start_game_for_all() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🎮 ЗАПУСК ИГРЫ!")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   Игроков: ", player_ids.size())
	print("   Список: ", player_ids)
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	game_started.emit()

func start_game() -> void:
	if is_host and player_ids.size() >= 2:
		print("🎮 Хост запускает игру для всех...")
		rpc("start_game_for_all")
