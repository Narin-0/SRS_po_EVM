extends Control


# Ссылка на узел AnimatedSprite2D
@onready var animated_sprite = $CenterContainer/AnimatedSprite2D

func _ready():
	# Запускаем анимацию с именем "default"
	animated_sprite.play("default")
