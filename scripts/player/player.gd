extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var max_health: int = 100
@export var invincibility_time: float = 1.5
@export var regen_delay: float = 15.0           # время простоя перед началом регенерации (в секундах)
@export var regen_speed: float = 80.0           # сколько HP в секунду восстанавливается
@export var regen_target: float = 0.7           # до какого процента максимум регенить (0.7 = 70%)
@export var regen_glow_intensity: float = 0.5   # интенсивность зелёного свечения

var health: float = max_health                  # теперь float для плавного восстановления
var anim_sprite: AnimatedSprite2D
var hp_bar: TextureProgressBar
var is_invincible: bool = false
var idle_time: float = 0.0                      # время без движения
var is_regening: bool = false                   # флаг регена


func _ready() -> void:
	anim_sprite = $AnimatedSprite2D
	hp_bar = $UI/HPBar
	$Inventory.add_item(load("res://items/flask_big_blue.png"))
	$Inventory.add_item(load("res://items/flask_big_green.png"))

	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = int(health)
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


func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO

	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector = input_vector.normalized()

	var is_running = Input.is_action_pressed("run")
	var speed = run_speed if is_running else walk_speed
	velocity = input_vector * speed

	# Проверяем, стоит ли игрок
	if input_vector == Vector2.ZERO:
		anim_sprite.play("idle")
		idle_time += delta
	else:
		idle_time = 0.0
		if is_running:
			anim_sprite.play("run")
		else:
			anim_sprite.play("walking")

		if input_vector.x != 0:
			anim_sprite.flip_h = input_vector.x < 0

	move_and_slide()

	# Пассивная регенерация HP
	_check_auto_regen(delta)


func _check_auto_regen(delta: float) -> void:
	var target_hp = max_health * regen_target
	if health <= max_health * 0.5 and idle_time >= regen_delay and health < target_hp:
		is_regening = true
		health += regen_speed * delta
		if health > target_hp:
			health = target_hp
		hp_bar.value = int(health)
		_apply_regen_glow(delta)
	else:
		if is_regening:
			# конец регена — возвращаем обычный цвет
			anim_sprite.modulate = Color(1, 1, 1, 1)
		is_regening = false


func _apply_regen_glow(delta: float) -> void:
	# Пульсирующее зелёное свечение
	var glow_strength = regen_glow_intensity * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0))
	anim_sprite.modulate = Color(1 - glow_strength, 1, 1 - glow_strength, 1)


func take_damage(amount: int) -> void:
	if is_invincible:
		return

	health -= amount
	if health < 0:
		health = 0
	hp_bar.value = int(health)

	_flash_white()

	_set_invincible(true)
	await get_tree().create_timer(invincibility_time).timeout
	_set_invincible(false)


func _flash_white():
	anim_sprite.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.15).timeout

	for i in range(5):
		anim_sprite.visible = false
		await get_tree().create_timer(0.1).timeout
		anim_sprite.visible = true
		await get_tree().create_timer(0.1).timeout


func _set_invincible(state: bool) -> void:
	is_invincible = state
	if state:
		modulate = Color(1, 1, 1, 0.6)
	else:
		modulate = Color(1, 1, 1, 1)


func heal(amount: int) -> void:
	health += amount
	if health > max_health:
		health = max_health
	hp_bar.value = int(health)


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		take_damage(10)
	if Input.is_action_just_pressed("ui_cancel"):
		heal(10)
