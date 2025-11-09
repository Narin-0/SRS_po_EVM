extends CharacterBody2D

# Константы
const WALK_SPEED = 150.0
const RUN_SPEED = 250.0
const STAMINA_DRAIN_RATE = 20.0  # в секунду
const STAMINA_REGEN_RATE = 15.0
const HP_REGEN_DELAY = 15.0  # секунд бездействия
const HP_REGEN_AMOUNT = 70.0  # процентов
const INVINCIBILITY_TIME = 1.0

# Характеристики
var max_hp = 100.0
var current_hp = 100.0
var max_stamina = 100.0
var current_stamina = 100.0

# Состояния
var is_invincible = false
var is_dead = false
var idle_timer = 0.0
var is_regenerating = false

# Ссылки на узлы
@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_timer = $DamageTimer
@onready var collision_shape = $CollisionShape2D
@onready var weapon_holder = $WeaponHolder
@onready var inventory = $Inventory

func _ready():
	damage_timer.wait_time = INVINCIBILITY_TIME
	damage_timer.one_shot = true
	damage_timer.timeout.connect(_on_invincibility_end)

func _physics_process(delta):
	if is_dead:
		return
	
	handle_movement(delta)
	handle_stamina(delta)
	handle_idle_regeneration(delta)
	handle_animations()

func handle_movement(delta):
	# Получение направления движения
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	input_vector = input_vector.normalized()
	
	# Проверка бега
	var is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 0
	var current_speed = RUN_SPEED if is_sprinting else WALK_SPEED
	
	# Применение движения
	if input_vector != Vector2.ZERO:
		velocity = input_vector * current_speed
		idle_timer = 0.0  # Сброс таймера бездействия
		
		# Расход выносливости при беге
		if is_sprinting:
			current_stamina -= STAMINA_DRAIN_RATE * delta
			current_stamina = max(0, current_stamina)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_speed)
		idle_timer += delta
	
	move_and_slide()
	
	# Поворот спрайта к курсору
	var mouse_pos = get_global_mouse_position()
	if mouse_pos.x < global_position.x:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

func handle_stamina(delta):
	# Восстановление выносливости
	if not Input.is_action_pressed("sprint") and current_stamina < max_stamina:
		current_stamina += STAMINA_REGEN_RATE * delta
		current_stamina = min(max_stamina, current_stamina)

func handle_idle_regeneration(delta):
	# Проверка бездействия для регенерации
	if idle_timer >= HP_REGEN_DELAY and not is_regenerating and current_hp < max_hp:
		start_hp_regeneration()

func start_hp_regeneration():
	is_regenerating = true
	var regen_amount = max_hp * (HP_REGEN_AMOUNT / 100.0)
	current_hp = min(max_hp, current_hp + regen_amount)
	
	# Визуальный эффект (зелёные частицы)
	spawn_heal_particles()
	
	# Завершение регенерации
	await get_tree().create_timer(0.5).timeout
	is_regenerating = false

func handle_animations():
	if velocity.length() > 0:
		if Input.is_action_pressed("sprint") and current_stamina > 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("walk")
	else:
		animated_sprite.play("idle")

func take_damage(amount: float):
	if is_invincible or is_dead:
		return
	
	current_hp -= amount
	current_hp = max(0, current_hp)
	idle_timer = 0.0  # Сброс регенерации
	
	# Визуальные эффекты урона
	start_damage_effect()
	spawn_damage_number(amount)
	
	# Запуск неуязвимости
	is_invincible = true
	damage_timer.start()
	
	# Проверка смерти
	if current_hp <= 0:
		die()

func start_damage_effect():
	# Эффект мигания
	var tween = create_tween()
	tween.set_loops(5)
	tween.tween_property(animated_sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(animated_sprite, "modulate:a", 1.0, 0.1)

func _on_invincibility_end():
	is_invincible = false
	animated_sprite.modulate.a = 1.0

func die():
	if is_dead:
		return
	
	is_dead = true
	animated_sprite.play("death")
	collision_shape.set_deferred("disabled", true)
	
	# Возрождение через 15 секунд
	await get_tree().create_timer(15.0).timeout
	respawn()

func respawn():
	is_dead = false
	current_hp = max_hp
	current_stamina = max_stamina
	collision_shape.disabled = false
	global_position = get_tree().get_first_node_in_group("spawn_point").global_position
	animated_sprite.play("idle")
	animated_sprite.modulate.a = 1.0

func spawn_damage_number(amount: float):
	# TODO: Создание всплывающих цифр урона
	pass

func spawn_heal_particles():
	# TODO: Создание частиц исцеления
	pass
	

func _input(event):
	if is_dead:
		return
	
	# Атака
	if event.is_action_pressed("attack"):
		var current_item = inventory.get_current_item()
		if current_item:
			current_item.use(self)
	
	# Взаимодействие
	if event.is_action_pressed("interact"):
		interact_with_nearby()

func interact_with_nearby():
	# Поиск близлежащих предметов
	var areas = $InteractionArea.get_overlapping_areas()
	for area in areas:
		if area.is_in_group("pickup"):
			# Предмет подберётся автоматически через свой скрипт
			pass
		elif area.is_in_group("mimic"):
			area.activate()

#func spawn_damage_number(amount: float):
#	var damage_number_scene = preload("res://scenes/Character/player_v_2/damage_number.tscn")
#	var damage_number = damage_number_scene.instantiate()
#	get_parent().add_child(damage_number)
#	damage_number.global_position = global_position + Vector2(0, -20)
#	damage_number.set_damage(amount)

#func spawn_heal_particles():
#	var particles_scene = preload("res://scenes/heal_particles.tscn")
#	var particles = particles_scene.instantiate()
#	add_child(particles)
#	particles.emitting = true
	
	# Удаление после завершения
#	await get_tree().create_timer(particles.lifetime).timeout
#	particles.queue_free()
