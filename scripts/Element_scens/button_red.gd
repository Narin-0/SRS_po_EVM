extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D # Убедитесь, что путь $AnimatedSprite2D верен!
var is_pressed = false

func _ready():
	# ИСПРАВЛЕНИЕ: Подключение сигналов Area2D к методам в этом же скрипте
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	anim.play("idle")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		is_pressed = true
		anim.play("pressed")
		print("Кнопка нажата!")

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		is_pressed = false
		anim.play("idle")
		print("Кнопка отпущена!")
