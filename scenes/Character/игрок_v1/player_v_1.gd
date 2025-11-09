extends CharacterBody2D

# Параметры движения
@export var walk_speed: float = 150.0
@export var run_speed: float = 250.0
@export var acceleration: float = 1000.0
@export var friction: float = 1000.0

# Характеристики
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_drain_rate: float = 20.0  # В секунду при беге
@export var stamina_regen_rate: float = 15.0  # В секунду в покое
@export var health_regen_percent: float = 0.5  # 50%
@export var health_regen_delay: float = 15.0
@export var invulnerability_duration: float = 0.5

# Текущие значения
var current_health: float
var current_stamina: float
var is_invulnerable: bool = false
var time_since_damage: float = 0.0
var last_direction: Vector2 = Vector2.DOWN

# Инвентарь
var inventory: Array = [null, null, null, null]  # 4 слота
var current_slot: int = 0

# Ссылки на узлы (с проверкой существования)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var item_holder: Node2D = $ItemHolder if has_node("ItemHolder") else null
@onready var item_sprite: Sprite2D = get_node_or_null("ItemHolder/ItemSprite")
@onready var hurt_timer: Timer = $HurtTimer if has_node("HurtTimer") else null
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer if has_node("InvulnerabilityTimer") else null
@onready var health_regen_timer: Timer = $HealthRegenTimer if has_node("HealthRegenTimer") else null
@onready var heal_particles: CPUParticles2D = $HealParticles if has_node("HealParticles") else null

func _ready():
	current_health = max_health
	current_stamina = max_stamina
	
	# Настройка таймеров (если существуют)
	if hurt_timer:
		hurt_timer.one_shot = true
	if invulnerability_timer:
		invulnerability_timer.one_shot = true
	if health_regen_timer:
		health_regen_timer.wait_time = health_regen_delay
		health_regen_timer.one_shot = true
	
	# Настройка частиц лечения (если существуют)
	if heal_particles:
		heal_particles.emitting = false
		heal_particles.one_shot = true
		heal_particles.amount = 20
		heal_particles.lifetime = 0.8
		heal_particles.speed_scale = 1.5
		heal_particles.color = Color.GREEN
	
	update_item_display()

func _physics_process(delta):
	handle_movement(delta)
	handle_stamina(delta)
	handle_health_regen(delta)
	handle_inventory_input()
	update_animation()
	move_and_slide()

# === ДВИЖЕНИЕ ===
func handle_movement(delta):
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector.length() > 0:
		last_direction = input_vector.normalized()
		
		# Определяем скорость (бег или ходьба)
		var is_sprinting = Input.is_action_pressed("sprint") and current_stamina > 0
		var target_speed = run_speed if is_sprinting else walk_speed
		
		# Если бежим, тратим выносливость
		if is_sprinting and input_vector.length() > 0:
			current_stamina -= stamina_drain_rate * delta
			current_stamina = max(0, current_stamina)
		
		velocity = velocity.move_toward(input_vector.normalized() * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

# === ВЫНОСЛИВОСТЬ ===
func handle_stamina(delta):
	# Восстанавливаем выносливость, если не бежим
	if not Input.is_action_pressed("sprint") or velocity.length() < 10:
		current_stamina += stamina_regen_rate * delta
		current_stamina = min(current_stamina, max_stamina)

# === ЗДОРОВЬЕ ===
func handle_health_regen(delta):
	# Если здоровье меньше половины
	if current_health < max_health * 0.5 and not is_invulnerable:
		time_since_damage += delta
		
		# Если прошло 15 секунд без урона
		if time_since_damage >= health_regen_delay:
			heal(max_health * health_regen_percent)
			time_since_damage = 0.0

func take_damage(amount: float):
	if is_invulnerable:
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	time_since_damage = 0.0  # Сброс таймера регенерации
	
	if current_health <= 0:
		die()
	else:
		start_invulnerability()

func heal(amount: float):
	current_health += amount
	current_health = min(current_health, max_health)
	
	# Эффект зелёных частиц (если существуют)
	if heal_particles:
		heal_particles.emitting = true

func start_invulnerability():
	is_invulnerable = true
	if invulnerability_timer:
		invulnerability_timer.start(invulnerability_duration)
	start_blink_effect()

func start_blink_effect():
	# Создаём эффект мигания на 1 секунду
	var blink_duration = 1.0
	var blink_count = 5
	var blink_interval = blink_duration / (blink_count * 2)
	
	for i in range(blink_count):
		await get_tree().create_timer(blink_interval).timeout
		modulate.a = 0.3
		await get_tree().create_timer(blink_interval).timeout
		modulate.a = 1.0

func die():
	if animated_sprite:
		animated_sprite.play("death")
	set_physics_process(false)
	# Здесь добавьте логику смерти (перезагрузка уровня и т.д.)

# === ИНВЕНТАРЬ ===
func handle_inventory_input():
	# Клавиши 1-4
	if Input.is_action_just_pressed("slot_1"):
		select_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		select_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		select_slot(2)
	elif Input.is_action_just_pressed("slot_4"):
		select_slot(3)
	
	# Колесо мыши
	if Input.is_action_just_pressed("scroll_up"):
		select_slot((current_slot - 1 + 4) % 4)
	elif Input.is_action_just_pressed("scroll_down"):
		select_slot((current_slot + 1) % 4)

func select_slot(slot_index: int):
	current_slot = slot_index
	update_item_display()

func add_item_to_inventory(item_data: Dictionary):
	# Ищем первый пустой слот
	for i in range(4):
		if inventory[i] == null:
			inventory[i] = item_data
			if i == current_slot:
				update_item_display()
			return true
	return false  # Инвентарь полон

func update_item_display():
	# Проверяем существование item_sprite перед использованием
	if not item_sprite or not is_instance_valid(item_sprite):
		return
		
	var current_item = inventory[current_slot]
	
	if current_item != null and current_item.has("texture"):
		item_sprite.texture = current_item.texture
		item_sprite.visible = true
	else:
		item_sprite.visible = false

# === АНИМАЦИИ ===
func update_animation():
	if not animated_sprite:
		return
		
	var is_moving = velocity.length() > 10
	var is_running = Input.is_action_pressed("sprint") and current_stamina > 0 and is_moving
	
	if not is_moving:
		animated_sprite.play("idle")
	elif is_running:
		animated_sprite.play("run")
	else:
		animated_sprite.play("walk")
	
	# Поворот спрайта в направлении движения
	if velocity.x != 0:
		animated_sprite.flip_h = velocity.x < 0

# Сигналы таймеров
func _on_invulnerability_timer_timeout():
	is_invulnerable = false
