extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var max_health: int = 100

var health: int = max_health
var anim_sprite: AnimatedSprite2D
var hp_bar: TextureProgressBar

func _ready() -> void:
	anim_sprite = $AnimatedSprite2D
	hp_bar = $UI/HPBar  # проверь, что путь совпадает!
	$Inventory.add_item(load("res://items/flask_big_blue.png"))
	$Inventory.add_item(load("res://items/flask_big_green.png"))
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health
	else:
		push_error("⚠️ HPBar не найден! Проверь путь $UI/HPBar")

	var cam = $Camera2D
	cam.enabled = true
	cam.make_current()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 5.0

func _input(event):
	if event.is_action_pressed("ui_right"):
		$Inventory.next_item()
	elif event.is_action_pressed("ui_left"):
		$Inventory.previous_item()



func _physics_process(_delta: float) -> void:
	var input_vector = Vector2.ZERO

	# Движение (WASD)
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector = input_vector.normalized()

	# Проверка Shift — бежим или идем
	var is_running = Input.is_action_pressed("run")
	var speed = run_speed if is_running else walk_speed
	velocity = input_vector * speed

	# Определяем анимацию
	if input_vector == Vector2.ZERO:
		anim_sprite.play("idle")
	else:
		if is_running:
			anim_sprite.play("run")
		else:
			anim_sprite.play("walking")

		# Отражаем спрайт при движении влево
		if input_vector.x != 0:
			anim_sprite.flip_h = input_vector.x < 0

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health < 0:
		health = 0
	hp_bar.value = health

func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
	hp_bar.value = health

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		take_damage(10)
	if Input.is_action_just_pressed("ui_cancel"):
		heal(10)
