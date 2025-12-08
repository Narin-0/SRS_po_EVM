# Скрипт прикреплен непосредственно к AnimatedSprite2D
extends AnimatedSprite2D

func _ready():
	# Чтобы вызвать метод play() на этом же узле, просто используйте play()
	play("default")
