extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0

var current_speed: float
var direction: Vector2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	direction = Vector2.ZERO

	# Управление (WASD или стрелки)
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	direction = direction.normalized()

	# Проверка на Shift (бег)
	if Input.is_action_pressed("run"): 
		current_speed = run_speed
	else:
		current_speed = walk_speed

	# Движение
	velocity = direction * current_speed
	move_and_slide()

	# Анимации
	if direction != Vector2.ZERO:
		if current_speed == run_speed:
			anim.play("run")
		else:
			anim.play("walking")
	else:
		anim.play("idle") 

	# Отражение по горизонтали
	if direction.x < 0:
		anim.flip_h = true
	elif direction.x > 0:
		anim.flip_h = false
