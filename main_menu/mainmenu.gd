@tool 
extends Control 

# Здесь указываем, какой узел ParallaxBackground будет управляться
# Путь $ParallaxBackground должен совпадать с названием узла в дереве сцен
@onready var parallax_background = $ParallaxBackground

# --- Настройки чувствительности ---
# Максимальное смещение в пикселях, которое разрешено фону (ограничивает движение)
const MAX_OFFSET = 50 
# Коэффициент, который определяет, насколько плавно фон следует за мышью (меньше = плавнее)
const SENSITIVITY = 0.05 

func _ready():
	# Проверяем, существует ли узел ParallaxBackground, прежде чем пытаться им управлять
	if not is_instance_valid(parallax_background):
		push_error("Узел ParallaxBackground не найден по пути: $ParallaxBackground")
		return
		
	# Включаем обработку ввода, если скрипт не в режиме инструмента (@tool)
	if not Engine.is_editor_hint():
		set_process_input(true)
		
# Функция для обработки ввода (движения мыши)
func _input(event):
	if event is InputEventMouseMotion:
		# 1. Получаем размер видимой области
		var viewport_size = get_viewport_rect().size
		
		# 2. Нормализуем позицию курсора (от -0.5 до 0.5, где 0,0 - центр экрана)
		var cursor_normalized = (get_global_mouse_position() / viewport_size) - Vector2(0.5, 0.5)
		
		# 3. Рассчитываем целевое смещение, умножая нормализованную позицию на лимит
		var target_offset = cursor_normalized * MAX_OFFSET
		
		# 4. Плавно интерполируем (сглаживаем) текущее смещение фона к целевому
		# (Используется _process или _input, чтобы избежать задержки)
		parallax_background.scroll_offset = lerp(
			parallax_background.scroll_offset,
			target_offset,
			SENSITIVITY
		)


func _on_soundbutton_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
