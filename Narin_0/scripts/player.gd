extends CharacterBody2D

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var max_health: int = 100
@export var invincibility_time: float = 1.5
@export var regen_delay: float = 15.0
@export var regen_speed: float = 80.0
@export var regen_target: float = 0.7

@export var max_stamina: int = 100
@export var stamina_depletion_rate: float = 25.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 1.2

var health: float = 0.0
var stamina: float = 0.0
var anim_sprite: AnimatedSprite2D
var hp_bar: TextureProgressBar  # Свой HP бар (в UI)
var stamina_bar: TextureProgressBar
var is_invincible: bool = false
var idle_time: float = 0.0
var is_regening: bool = false
var _original_modulate: Color
var is_dead: bool = false

var _stamina_regen_timer: float = 0.0
var _is_sprinting: bool = false

var death_menu: Control
var _spawn_position: Vector2
@export var respawn_invincibility: float = 1.2

@onready var gun_sprite = $GunAnchor/GunSprite2D

# 🌐 СЕТЕВЫЕ ПЕРЕМЕННЫЕ
var player_id: int = 0
var _sync_timer: float = 0.0
var _sync_interval: float = 0.1

# HP бар над головой (для врагов)
var enemy_hp_bar: TextureProgressBar
var enemy_hp_container: Control

# Переменные для удалённых игроков
var _remote_position: Vector2 = Vector2.ZERO
var _remote_animation: String = "idle"
var _remote_flip: bool = false

func _ready() -> void:
	anim_sprite = $AnimatedSprite2D
	hp_bar = $UI/HPBar
	stamina_bar = get_node_or_null("UI/StaminaBar")
	gun_sprite = get_node_or_null("GunAnchor/GunSprite2D")
	
	_original_modulate = modulate
	add_to_group("player")

	health = float(max_health)
	stamina = float(max_stamina)
	
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = int(health)

	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = int(stamina)

	_spawn_position = global_position

	death_menu = get_node_or_null("UI/DeathMenu")
	if death_menu:
		var resp_btn = death_menu.get_node_or_null("RespawnButton")
		var quit_btn = death_menu.get_node_or_null("QuitButton")
		if resp_btn:
			resp_btn.pressed.connect(Callable(self, "_on_respawn_pressed"))
		if quit_btn:
			quit_btn.pressed.connect(Callable(self, "_on_quit_pressed"))
		death_menu.hide()

	var cam = $Camera2D
	cam.enabled = is_multiplayer_authority()
	if cam.enabled:
		cam.make_current()

	player_id = get_multiplayer_authority()
	_remote_position = global_position
	
	# 🎯 Настройка UI в зависимости от владельца
	if is_multiplayer_authority():
		# Это МОЙ игрок - показываем полный UI
		if hp_bar:
			hp_bar.visible = true
		if stamina_bar:
			stamina_bar.visible = true
		
		print("👤 Мой игрок %d готов" % player_id)
	else:
		# Это ЧУЖОЙ игрок - скрываем UI и создаём HP бар над головой
		if hp_bar:
			hp_bar.visible = false
		if stamina_bar:
			stamina_bar.visible = false
		if death_menu:
			death_menu.visible = false
		
		_create_enemy_hp_bar()
		
		print("👥 Противник %d появился" % player_id)

func _create_enemy_hp_bar() -> void:
	"""Создаёт HP бар над головой противника"""
	
	# Контейнер для позиционирования
	enemy_hp_container = Control.new()
	enemy_hp_container.position = Vector2(-25, -20)  # Над головой
	enemy_hp_container.z_index = 100  # Поверх всего
	add_child(enemy_hp_container)
	
	# Фон HP бара
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2, 0.8)  # Тёмно-серый фон
	bg.size = Vector2(52, 8)
	bg.position = Vector2(-1, -1)
	enemy_hp_container.add_child(bg)
	
	# HP бар
	enemy_hp_bar = TextureProgressBar.new()
	enemy_hp_bar.size = Vector2(50, 6)
	enemy_hp_bar.max_value = max_health
	enemy_hp_bar.value = max_health
	
	# Создаём текстуры программно (если нет готовых)
	_setup_hp_bar_textures()
	
	enemy_hp_container.add_child(enemy_hp_bar)
	
	# Опционально: добавить имя игрока
	var name_label = Label.new()
	name_label.text = "Player %d" % player_id
	name_label.position = Vector2(0, -15)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 5)
	enemy_hp_container.add_child(name_label)

func _setup_hp_bar_textures() -> void:
	"""Создаёт простые текстуры для HP бара если их нет"""
	
	# Если у вас уже есть текстуры - раскомментируйте это:
	# enemy_hp_bar.texture_under = preload("res://path/to/hp_bg.png")
	# enemy_hp_bar.texture_progress = preload("res://path/to/hp_fill.png")
	# return
	
	# Создаём простые градиентные текстуры программно
	var bg_texture = _create_solid_texture(Vector2(50, 6), Color(0.3, 0.3, 0.3))
	var fill_texture = _create_gradient_texture(Vector2(50, 6), 
		Color(1.0, 0.2, 0.2),  # Красный
		Color(0.8, 0.0, 0.0))   # Тёмно-красный
	
	enemy_hp_bar.texture_under = bg_texture
	enemy_hp_bar.texture_progress = fill_texture

func _create_solid_texture(size: Vector2, color: Color) -> Texture2D:
	"""Создаёт одноцветную текстуру"""
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _create_gradient_texture(size: Vector2, color1: Color, color2: Color) -> Texture2D:
	"""Создаёт градиентную текстуру"""
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	for x in range(int(size.x)):
		var t = float(x) / size.x
		var color = color1.lerp(color2, t)
		for y in range(int(size.y)):
			img.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(img)

func _input(event):
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("ui_right"):
		$Inventory.next_item()
	elif event.is_action_pressed("ui_left"):
		$Inventory.previous_item()

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		_handle_local_player(delta)
	else:
		_handle_remote_player(delta)

func _handle_local_player(delta: float) -> void:
	if is_dead:
		return
	
	# ВВОД
	var input_vector = Vector2.ZERO
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector = input_vector.normalized()

	var run_pressed = Input.is_action_pressed("run")
	if run_pressed and input_vector != Vector2.ZERO and stamina > 0.0:
		_is_sprinting = true
	else:
		_is_sprinting = false

	var speed = run_speed if _is_sprinting else walk_speed
	velocity = input_vector * speed

	# АНИМАЦИЯ
	var current_animation = ""
	if input_vector == Vector2.ZERO:
		current_animation = "idle"
		idle_time += delta
	else:
		idle_time = 0.0
		current_animation = "run" if _is_sprinting else "walking"
		if input_vector.x != 0:
			anim_sprite.flip_h = input_vector.x < 0

	if anim_sprite.animation != current_animation:
		anim_sprite.play(current_animation)

	move_and_slide()

	# ОРУЖИЕ
	if is_instance_valid(gun_sprite):
		var mouse_x = get_global_mouse_position().x
		var flip = mouse_x < global_position.x
		anim_sprite.flip_h = flip
		gun_sprite.flip_h = flip

	# 🎯 HP и STAMINA обрабатываются ТОЛЬКО у владельца
	_handle_stamina(delta)
	_check_auto_regen(delta)
	
	# Обновляем свои UI бары
	if hp_bar:
		hp_bar.value = int(health)
	if stamina_bar:
		stamina_bar.value = int(stamina)

	# 🌐 СИНХРОНИЗАЦИЯ
	_sync_timer += delta
	if _sync_timer >= _sync_interval:
		_sync_timer = 0.0
		# Отправляем визуальное состояние + HP для отображения над головой
		_sync_visual_state.rpc(global_position, current_animation, anim_sprite.flip_h, int(health))

# 🌐 RPC для синхронизации визуального состояния
@rpc("unreliable")
func _sync_visual_state(pos: Vector2, anim: String, flip: bool, hp: int) -> void:
	# Получаем данные от других игроков
	if is_multiplayer_authority():
		return
	
	_remote_position = pos
	_remote_animation = anim
	_remote_flip = flip
	
	# Обновляем HP бар над головой противника
	if enemy_hp_bar:
		enemy_hp_bar.value = hp
		
		# Опционально: меняем цвет в зависимости от HP
		_update_hp_bar_color(hp)

func _update_hp_bar_color(hp: int) -> void:
	"""Меняет цвет HP бара в зависимости от здоровья"""
	if not enemy_hp_bar:
		return
	
	var hp_percent = float(hp) / float(max_health)
	
	var color_high = Color(0.2, 1.0, 0.2)   # Зелёный (100% HP)
	var color_mid = Color(1.0, 1.0, 0.2)    # Жёлтый (50% HP)
	var color_low = Color(1.0, 0.2, 0.2)    # Красный (0% HP)
	
	var final_color: Color
	if hp_percent > 0.5:
		# Интерполяция от зелёного к жёлтому
		var t = (1.0 - hp_percent) * 2.0
		final_color = color_high.lerp(color_mid, t)
	else:
		# Интерполяция от жёлтого к красному
		var t = (0.5 - hp_percent) * 2.0
		final_color = color_mid.lerp(color_low, t)
	
	# Применяем цвет через tint
	enemy_hp_bar.tint_progress = final_color

func _handle_remote_player(delta: float) -> void:
	# Плавная интерполяция позиции
	global_position = global_position.lerp(_remote_position, 0.15)
	
	# Обновляем анимацию
	if anim_sprite.animation != _remote_animation:
		anim_sprite.animation = _remote_animation
		anim_sprite.play()
	
	if anim_sprite.flip_h != _remote_flip:
		anim_sprite.flip_h = _remote_flip

func take_damage(amount: float) -> void:
	# Только владелец может получать урон
	if is_multiplayer_authority():
		_apply_damage(amount)

func _apply_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return

	health -= amount
	health = max(0.0, health)
	if hp_bar:
		hp_bar.value = int(health)

	_flash_white()

	if health <= 0:
		is_dead = true
		_on_death()
		# Уведомляем всех о смерти
		_sync_death.rpc()
		return

	_set_invincible(true)
	await get_tree().create_timer(invincibility_time).timeout
	if not is_dead:
		_set_invincible(false)

@rpc("reliable")
func _sync_death() -> void:
	"""Синхронизирует смерть игрока для всех"""
	if not is_multiplayer_authority():
		if enemy_hp_bar:
			enemy_hp_bar.value = 0
		if anim_sprite:
			anim_sprite.play("death")

func _on_death() -> void:
	velocity = Vector2.ZERO
	set_physics_process(false)

	var cs = get_node_or_null("CollisionShape2D")
	if cs:
		cs.set_deferred("disabled", true)

	if anim_sprite:
		anim_sprite.play("death")

	await get_tree().create_timer(0.5).timeout

	if death_menu:
		death_menu.show()

func _on_respawn_pressed() -> void:
	if death_menu:
		death_menu.hide()

	health = float(max_health)
	stamina = float(max_stamina)
	if hp_bar:
		hp_bar.value = int(health)
	if stamina_bar:
		stamina_bar.value = int(stamina)

	global_position = _spawn_position

	set_physics_process(true)
	var cs = get_node_or_null("CollisionShape2D")
	if cs:
		cs.disabled = false

	is_dead = false
	
	# Уведомляем всех о респавне
	_sync_respawn.rpc()
	
	_set_invincible(true)
	await get_tree().create_timer(respawn_invincibility).timeout
	if not is_dead:
		_set_invincible(false)

	if anim_sprite:
		anim_sprite.play("idle")

@rpc("reliable")
func _sync_respawn() -> void:
	"""Синхронизирует респавн игрока для всех"""
	if not is_multiplayer_authority():
		if enemy_hp_bar:
			enemy_hp_bar.value = max_health
		if anim_sprite:
			anim_sprite.play("idle")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _handle_stamina(delta: float) -> void:
	if _is_sprinting:
		stamina -= stamina_depletion_rate * delta
		_stamina_regen_timer = 0.0
		if stamina <= 0.0:
			stamina = 0.0
			_is_sprinting = false
	else:
		_stamina_regen_timer += delta
		if _stamina_regen_timer >= stamina_regen_delay:
			if stamina < max_stamina:
				stamina += stamina_regen_rate * delta
				stamina = min(stamina, float(max_stamina))

func _check_auto_regen(delta: float) -> void:
	var target_hp = max_health * regen_target
	if health <= max_health * 0.5 and idle_time >= regen_delay and health < target_hp:
		if not is_regening:
			is_regening = true
		health += regen_speed * delta
		health = min(health, target_hp)
	else:
		if is_regening:
			anim_sprite.modulate = _original_modulate
			is_regening = false

func _flash_white() -> void:
	if anim_sprite:
		anim_sprite.modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout

	for i in range(4):
		if anim_sprite:
			anim_sprite.visible = false
		await get_tree().create_timer(0.08).timeout
		if anim_sprite:
			anim_sprite.visible = true
		await get_tree().create_timer(0.08).timeout

	if anim_sprite:
		anim_sprite.modulate = _original_modulate

func _set_invincible(state: bool) -> void:
	is_invincible = state
	modulate = Color(_original_modulate.r, _original_modulate.g, _original_modulate.b, 0.5 if state else 1.0)
