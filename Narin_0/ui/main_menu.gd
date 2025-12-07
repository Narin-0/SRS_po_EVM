extends Control

# Узлы с проверкой на null
var host_button: Button
var join_button: Button
var ip_input: LineEdit
var status_label: Label
var player_count_label: Label

var connection_timeout: float = 5.0
var timeout_timer: Timer

func _ready() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🔍 ПРОВЕРКА УЗЛОВ UI")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	# Ищем узлы разными способами
	_find_nodes()
	
	# Проверяем что нашлось
	_validate_nodes()
	
	# Если критичные узлы не найдены - создаём UI программно
	if not host_button or not join_button or not status_label:
		print("⚠️ Критичные узлы не найдены!")
		print("📦 Создаю UI программно...")
		_create_ui_programmatically()
		return
	
	# Настройка найденных узлов
	_setup_ui()
	
	print("✅ UI готов к работе")
	print("━━━━━━━━━━━━━━━━━━━━━━━━\n")

func _find_nodes() -> void:
	# Пробуем найти узлы разными способами
	
	# Способ 1: Уникальные имена (%)
	host_button = get_node_or_null("%HostButton")
	join_button = get_node_or_null("%JoinButton")
	ip_input = get_node_or_null("%IPInput")
	status_label = get_node_or_null("%StatusLabel")
	player_count_label = get_node_or_null("%PlayerCountLabel")
	
	# Способ 2: Если не нашли через %, пробуем через $
	if not host_button:
		host_button = get_node_or_null("VBoxContainer/HostButton")
	if not join_button:
		join_button = get_node_or_null("VBoxContainer/JoinButton")
	if not ip_input:
		ip_input = get_node_or_null("VBoxContainer/IPInput")
	if not status_label:
		status_label = get_node_or_null("VBoxContainer/StatusLabel")
	if not player_count_label:
		player_count_label = get_node_or_null("VBoxContainer/PlayerCountLabel")
	
	# Способ 3: Ищем по всему дереву
	if not host_button:
		host_button = _find_node_by_name("HostButton")
	if not join_button:
		join_button = _find_node_by_name("JoinButton")
	if not ip_input:
		ip_input = _find_node_by_name("IPInput")
	if not status_label:
		status_label = _find_node_by_name("StatusLabel")

func _find_node_by_name(node_name: String) -> Node:
	return _search_children(self, node_name)

func _search_children(node: Node, search_name: String) -> Node:
	if node.name == search_name:
		return node
	for child in node.get_children():
		var result = _search_children(child, search_name)
		if result:
			return result
	return null

func _validate_nodes() -> void:
	print("host_button: ", "✅ НАЙДЕНА" if host_button else "❌ НЕ НАЙДЕНА")
	print("join_button: ", "✅ НАЙДЕНА" if join_button else "❌ НЕ НАЙДЕНА")
	print("ip_input: ", "✅ НАЙДЕН" if ip_input else "❌ НЕ НАЙДЕН")
	print("status_label: ", "✅ НАЙДЕН" if status_label else "❌ НЕ НАЙДЕН")
	print("player_count_label: ", "✅ НАЙДЕН" if player_count_label else "⚠️ НЕ НАЙДЕН (опционально)")

func _setup_ui() -> void:
	# Подключение кнопок
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
	
	# Настройка поля ввода
	if not ip_input:
		# Создаём поле ввода программно
		ip_input = LineEdit.new()
		ip_input.name = "IPInput"
		ip_input.custom_minimum_size = Vector2(200, 40)
		
		# Вставляем в VBoxContainer после join_button
		if join_button and join_button.get_parent():
			var parent = join_button.get_parent()
			var index = join_button.get_index() + 1
			parent.add_child(ip_input)
			parent.move_child(ip_input, index)
			print("📦 IPInput создан программно")
	
	if ip_input:
		ip_input.text = "127.0.0.1"
		ip_input.placeholder_text = "Введите IP"
		ip_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
		if ip_input is LineEdit:
			ip_input.text_submitted.connect(_on_ip_submitted)
	
	# Создаём label для счётчика если нет
	if not player_count_label and status_label:
		player_count_label = Label.new()
		player_count_label.name = "PlayerCountLabel"
		player_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var parent = status_label.get_parent()
		if parent:
			parent.add_child(player_count_label)
			parent.move_child(player_count_label, status_label.get_index())
			print("📦 PlayerCountLabel создан программно")
	
	# Подключение сигналов NetworkManager
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	
	# Таймер для таймаута
	timeout_timer = Timer.new()
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(_on_connection_timeout)
	add_child(timeout_timer)
	
	_update_player_count()

func _create_ui_programmatically() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🏗️ СОЗДАНИЕ UI С НУЛЯ")
	print("━━━━━━━━━━━━━━━━━━━━━━━━")
	
	# Очищаем существующих детей
	for child in get_children():
		child.queue_free()
	
	# Создаём контейнер
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	# Заголовок
	var title = Label.new()
	title.text = "Выберите режим"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Отступ
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Кнопка Host
	host_button = Button.new()
	host_button.text = "Создать игру"
	host_button.custom_minimum_size = Vector2(200, 50)
	host_button.pressed.connect(_on_host_pressed)
	vbox.add_child(host_button)
	
	# Кнопка Join
	join_button = Button.new()
	join_button.text = "Присоединиться"
	join_button.custom_minimum_size = Vector2(200, 50)
	join_button.pressed.connect(_on_join_pressed)
	vbox.add_child(join_button)
	
	# Поле ввода IP
	ip_input = LineEdit.new()
	ip_input.text = "127.0.0.1"
	ip_input.placeholder_text = "Введите IP"
	ip_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_input.custom_minimum_size = Vector2(200, 40)
	ip_input.text_submitted.connect(_on_ip_submitted)
	vbox.add_child(ip_input)
	
	# Счётчик игроков
	player_count_label = Label.new()
	player_count_label.text = "👥 Игроков: 0/4"
	player_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(player_count_label)
	
	# Статус
	status_label = Label.new()
	status_label.text = "Введите IP сервера"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(status_label)
	
	# Подключение сигналов NetworkManager
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.game_started.connect(_on_game_started)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	
	# Таймер
	timeout_timer = Timer.new()
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(_on_connection_timeout)
	add_child(timeout_timer)
	
	_update_player_count()
	
	print("✅ UI создан программно")
	print("━━━━━━━━━━━━━━━━━━━━━━━━\n")

func _update_player_count() -> void:
	if player_count_label:
		var count = NetworkManager.player_ids.size()
		player_count_label.text = "👥 Игроков: %d/%d" % [count, NetworkManager.MAX_PLAYERS]

func _on_host_pressed() -> void:
	print("\n🎯 UI: Нажата кнопка 'Создать игру'\n")
	NetworkManager.host_game()
	
	if status_label:
		status_label.text = "🖥️ Сервер создан\nОжидаю игроков..."
	
	if host_button:
		host_button.disabled = true
	if join_button:
		join_button.disabled = true
	if ip_input:
		ip_input.visible = false

func _on_join_pressed() -> void:
	print("\n🎯 UI: Нажата кнопка 'Присоединиться'\n")
	
	if not ip_input:
		push_error("IPInput не найден!")
		return
	
	var ip = ip_input.text.strip_edges()
	
	if ip.is_empty():
		if status_label:
			status_label.text = "❌ Введите IP!"
		ip_input.grab_focus()
		return
	
	print("🎯 UI: Попытка подключения к ", ip)
	NetworkManager.join_game(ip)
	
	if status_label:
		status_label.text = "🔄 Подключение к\n" + ip + "..."
	
	# Запускаем таймаут
	if timeout_timer:
		timeout_timer.start(connection_timeout)
	
	if host_button:
		host_button.disabled = true
	if join_button:
		join_button.disabled = true
	if ip_input:
		ip_input.editable = false

func _on_ip_submitted(text: String) -> void:
	_on_join_pressed()

func _on_connection_timeout() -> void:
	print("\n⏰ UI: Таймаут подключения!\n")
	if status_label:
		status_label.text = "❌ Таймаут подключения!\nСервер не отвечает"
	_reset_ui()

func _on_player_connected() -> void:
	if timeout_timer:
		timeout_timer.stop()
	
	var count = NetworkManager.player_ids.size()
	print("\n🎯 UI: Обновление счётчика игроков: ", count, "\n")
	
	_update_player_count()
	
	if status_label:
		status_label.text = "✅ Подключено игроков: %d/%d" % [count, NetworkManager.MAX_PLAYERS]
	
	if NetworkManager.is_host and count >= 2:
		if status_label:
			status_label.text += "\n⏳ Старт через 2 сек..."
		await get_tree().create_timer(2.0).timeout
		NetworkManager.start_game()

func _on_connection_succeeded() -> void:
	if timeout_timer:
		timeout_timer.stop()
	print("\n🎯 UI: Подключение успешно!\n")
	if status_label:
		status_label.text = "✅ Подключено!\nОжидаю других игроков..."

func _on_connection_failed() -> void:
	if timeout_timer:
		timeout_timer.stop()
	print("\n🎯 UI: Ошибка подключения!\n")
	if status_label:
		status_label.text = "❌ Не удалось подключиться!\n\nПроверьте:\n• Сервер запущен?\n• IP правильный?\n• Порт открыт?"
	_reset_ui()

func _reset_ui() -> void:
	if host_button:
		host_button.disabled = false
	if join_button:
		join_button.disabled = false
	if ip_input:
		ip_input.editable = true
		ip_input.grab_focus()

func _on_game_started() -> void:
	print("\n🎯 UI: Игра начинается!\n")
	_start_game()

func _start_game() -> void:
	if status_label:
		status_label.text = "🎮 Загрузка игры..."
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/levels/test_karta_2d.tscn")
