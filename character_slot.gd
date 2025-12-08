
extends CenterContainer

# Экспортируемая переменная для уникального ID персонажа
@export var character_id: String = ""

# Сигнал, который будет испускаться при нажатии на кнопку
signal character_selected(id)

func _ready():
	# Убедитесь, что AnimatedSprite2D запускает анимацию
	# (Предполагается, что AnimatedSprite2D является дочерним элементом этого CenterContainer)
	$AnimatedSprite2D.play("default")

func _on_TextureButton_pressed():
	# Испускаем сигнал, передавая уникальный ID персонажа
	# Этот сигнал будет пойман родительским интерфейсом
	emit_signal("character_selected", character_id)

# 🔔 Не забудьте подключить сигнал 'pressed()' вашей кнопки 
# к этой функции '_on_TextureButton_pressed()' в Инспекторе Узлов!
