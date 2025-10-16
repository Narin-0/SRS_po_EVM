extends Button

# Флаг для отслеживания текущего состояния звука.
var is_muted = false

# --- Инициализация ---

func _ready():
	# Проверяем начальное состояние Master-шины, чтобы правильно отобразить текст
	is_muted = AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	update_text()

# --- Обработка нажатия кнопки ---

func _on_pressed():
	# Меняем состояние: если было выключено, станет включено, и наоборот.
	is_muted = !is_muted
	
	# Получаем индекс главной (Master) шины звука.
	var master_bus_index = AudioServer.get_bus_index("Master")
	
	# Применяем заглушение ко всей игре.
	AudioServer.set_bus_mute(master_bus_index, is_muted)
	
	# Обновляем текст на кнопке.
	update_text()

# --- Вспомогательная функция ---

func update_text():
	# Устанавливаем текст и иконку в зависимости от состояния is_muted.
	if is_muted:
		text = "🔇ВЫКЛ"
	else:
		text = "🔊 ВКЛ"
