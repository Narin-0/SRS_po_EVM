extends Node2D

# Контейнер с позициями спавна из редактора
@onready var spawn_positions_container = $SpawnPositions

var player_scene: PackedScene = preload("res://Narin_0/scenes/player.tscn")
var players: Dictionary = {}
var spawn_positions: Array[Vector2] = []

func _ready() -> void:
	# Собираем все позиции из маркеров в сцене
	_collect_spawn_positions_from_scene()
	
	multiplayer.peer_connected.connect(_on_peer_connected_to_level)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected_from_level)
	
	var my_id = multiplayer.get_unique_id()
	var is_host = multiplayer.is_server()
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🎮 УРОВЕНЬ ЗАГРУЖЕН")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("   Мой ID: %d" % my_id)
	print("   Я хост: %s" % is_host)
	print("   Игроков: %s" % NetworkManager.player_ids)
	print("   Позиций спавна: %d" % spawn_positions.size())
	
	# Выводим все позиции для проверки
	for i in range(spawn_positions.size()):
		print("   📍 Позиция %d: %s" % [i + 1, spawn_positions[i]])
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	await get_tree().create_timer(0.2).timeout
	
	if is_host:
		print("🖥️ Я хост - спавню всех игроков:")
		_spawn_all_players()
	else:
		print("📱 Я клиент - запрашиваю список игроков")
		rpc_id(1, "request_spawn_players")

# Собираем позиции из маркеров в сцене
func _collect_spawn_positions_from_scene() -> void:
	spawn_positions.clear()
	
	if not spawn_positions_container:
		push_error("❌ Контейнер SpawnPositions не найден! Создайте Node2D с именем 'SpawnPositions'")
		return
	
	# Проходим по всем дочерним узлам контейнера
	for child in spawn_positions_container.get_children():
		# Принимаем Marker2D, Node2D или любой узел с позицией
		if child is Node2D:
			spawn_positions.append(child.global_position)
			print("✅ Загружена позиция из '%s': %s" % [child.name, child.global_position])
	
	if spawn_positions.is_empty():
		push_error("❌ В контейнере SpawnPositions нет дочерних узлов!")
		push_error("   Добавьте Marker2D узлы в SpawnPositions и расставьте их на карте")
	else:
		print("✅ Загружено %d позиций спавна" % spawn_positions.size())

# Получить позицию для игрока
func _get_spawn_position(index: int) -> Vector2:
	if spawn_positions.is_empty():
		push_error("Нет позиций спавна! Игрок появится в (0,0)")
		return Vector2.ZERO
	
	# Если игроков больше чем позиций - повторяем позиции
	var safe_index = index % spawn_positions.size()
	return spawn_positions[safe_index]

# Спавн всех игроков
func _spawn_all_players() -> void:
	var index = 0
	for player_id in NetworkManager.player_ids:
		var pos = _get_spawn_position(index)
		
		_spawn_player_local(player_id, pos)
		rpc("spawn_player_remote", player_id, pos)
		
		print("   ✅ Игрок %d → Позиция %d: %s" % [player_id, index + 1, pos])
		index += 1
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━\n")

func _spawn_player_local(player_id: int, pos: Vector2) -> void:
	if players.has(player_id):
		print("   ⚠️ Игрок %d уже существует" % player_id)
		return
	
	var player = player_scene.instantiate()
	player.name = "Player_%d" % player_id
	player.set_multiplayer_authority(player_id)
	player.global_position = pos
	
	if "player_id" in player:
		player.player_id = player_id
	
	add_child(player)
	players[player_id] = player
	
	var is_mine = player_id == multiplayer.get_unique_id()
	print("      👤 Создан: Player_%d %s" % [player_id, "(ЭТО Я!)" if is_mine else ""])

@rpc("any_peer", "call_remote", "reliable")
func request_spawn_players() -> void:
	if not multiplayer.is_server():
		return
	
	var requester_id = multiplayer.get_remote_sender_id()
	print("📥 Запрос на спавн от клиента %d" % requester_id)
	
	for player_id in NetworkManager.player_ids:
		if players.has(player_id):
			var pos = players[player_id].global_position
			rpc_id(requester_id, "spawn_player_remote", player_id, pos)

@rpc("any_peer", "call_remote", "reliable")
func spawn_player_remote(player_id: int, pos: Vector2) -> void:
	print("📥 RPC: Спавн игрока %d на %s" % [player_id, pos])
	_spawn_player_local(player_id, pos)

func _on_peer_connected_to_level(id: int) -> void:
	if multiplayer.is_server():
		print("🔗 Новый игрок %d подключился к уровню" % id)
		await get_tree().create_timer(0.5).timeout
		
		# Отправляем существующих игроков
		for player_id in players.keys():
			var pos = players[player_id].global_position
			rpc_id(id, "spawn_player_remote", player_id, pos)
		
		# Спавним нового игрока на следующей свободной позиции
		var index = players.size()
		var pos = _get_spawn_position(index)
		_spawn_player_local(id, pos)
		rpc("spawn_player_remote", id, pos)

func _on_peer_disconnected_from_level(id: int) -> void:
	print("👋 Игрок %d отключился" % id)
	
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	
	rpc("remove_player_remote", id)

@rpc("any_peer", "call_remote", "reliable")
func remove_player_remote(player_id: int) -> void:
	if players.has(player_id):
		players[player_id].queue_free()
		players.erase(player_id)
		print("🗑️ Удалён игрок %d" % player_id)
