extends CanvasLayer


# Ссылка на себя для удобства
@onready var menu_container = $ColorRect 

func _ready():
	# Изначально меню должно быть скрыто
	menu_container.hide()
	# Убедиться, что игра не на паузе в начале
	get_tree().paused = false

# Функция для вызова паузы/продолжения
func toggle_pause():
	# Меняем состояние паузы
	get_tree().paused = not get_tree().paused
	
	# Меняем видимость меню:
	if get_tree().paused:
		menu_container.show()
	else:
		menu_container.hide()

func _on_button_pressed() -> void:
	toggle_pause()


func _on_button_7_pressed() -> void:
	get_tree().quit()


func _on_button_6_pressed() -> void:
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://main_menu/mainmenu.tscn")
