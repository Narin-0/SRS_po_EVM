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
var hp_bar: TextureProgressBar
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

# 🔫 СИСТЕМА ОРУЖИЯ
@onready var gun_sprite = $GunAnchor/GunSprite2D
@onready var gun_anchor = $GunAnchor
@onready var muzzle_point = $GunAnchor/Muzzle

var weapon_manager: WeaponManager
var is_shooting: bool = false

# Сцены оружия (назначьте в редакторе или создайте программно)
@export var pistol_scene: PackedScene
@export var machinegun_scene: PackedScene
@export var shotgun_scene: PackedScene
@export var laser_scene: PackedScene

# 🌐 СЕТЕВЫЕ ПЕРЕМЕННЫЕ
var player_id: int = 0
var _sync_timer: float = 0.0
var _sync_interval: float = 0.1

var enemy_hp_bar: TextureProgressBar
var enemy_hp_container: Control

var _remote_position: Vector2 = Vector2.ZERO
var _remote_animation: String = "idle"
var _remote_flip: bool = false

func _ready() -> void:
	anim_sprite = $AnimatedSprite2D
	hp_bar = $UI/HPBar
	stamina_bar = get_node_or_null("UI/StaminaBar")
	
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
	
	# 🔫 ИНИЦИАЛИЗАЦИЯ СИСТЕМЫ ОРУЖИЯ
	if is_multiplayer_authority():
		_setup_weapon_system()
	
	if is_multiplayer_authority():
		if hp_bar:
			hp_bar.visible = true
		if stamina_bar:
			stamina_bar.visible = true
		
		print("👤 Мой игрок %d готов" % player_id)
	else:
		if hp_bar:
			hp_bar.visible = false
		if stamina_bar:
			stamina_bar.visible = false
		if death_menu:
			death_menu.visible = false
		
		_create_enemy_hp_bar()
		
		print("👥 Противник %d появился" % player_id)

func _setup_weapon_system() -> void:
	"""Настройка системы оружия"""
	weapon_manager = WeaponManager.new()
	add_child(weapon_manager)
	weapon_manager.setup(self, muzzle_point, gun_sprite)
	
	# Добавляем оружие (создайте сцены или инстанцируйте скрипты)
	var pistol = PistolWeapon.new()
	pistol.projectile_scene = preload("res://Narin_0/predmety/weapons/scenes/Projectile.tscn")  # Укажите путь
	weapon_manager.add_weapon(pistol)
	
	var machinegun = MachineGunWeapon.new()
	machinegun.projectile_scene = preload("res://Narin_0/predmety/weapons/scenes/Projectile.tscn")
	weapon_manager.add_weapon(machinegun)
	
	var shotgun = ShotgunWeapon.new()
	shotgun.projectile_scene = preload("res://Narin_0/predmety/weapons/scenes/Projectile.tscn")
	weapon_manager.add_weapon(shotgun)
	
	var laser = LaserWeapon.new()
	weapon_manager.add_weapon(laser)

func _create_enemy_hp_bar() -> void:
	"""Создаёт HP бар над головой противника"""
	enemy_hp_container = Control.new()
	enemy_hp_container.position = Vector2(-25, -20)
	enemy_hp_container.z_index = 100
	add_child(enemy_hp_container)
	
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	bg.size = Vector2(52, 8)
	bg.position = Vector2(-1, -1)
	enemy_hp_container.add_child(bg)
	
	enemy_hp_bar = TextureProgressBar.new()
	enemy_hp_bar.size = Vector2(50, 6)
	enemy_hp_bar.max_value = max_health
	enemy_hp_bar.value = max_health
	
	_setup_hp_bar_textures()
	
	enemy_hp_container.add_child(enemy_hp_bar)
	
	var name_label = Label.new()
	name_label.text = "Player %d" % player_id
	name_label.position = Vector2(0, -15)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 5)
	enemy_hp_container.add_child(name_label)

func _setup_hp_bar_textures() -> void:
	var bg_texture = _create_solid_texture(Vector2(50, 6), Color(0.3, 0.3, 0.3))
	var fill_texture = _create_gradient_texture(Vector2(50, 6), 
		Color(1.0, 0.2, 0.2),
		Color(0.8, 0.0, 0.0))
	
	enemy_hp_bar.texture_under = bg_texture
	enemy_hp_bar.texture_progress = fill_texture

func _create_solid_texture(size: Vector2, color: Color) -> Texture2D:
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)

func _create_gradient_texture(size: Vector2, color1: Color, color2: Color) -> Texture2D:
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
	
	# 🔫 ПЕРЕКЛЮЧЕНИЕ ОРУЖИЯ
	if event.is_action_pressed("slot_1"):
		weapon_manager.switch_weapon(0)
	elif event.is_action_pressed("slot_2"):
		weapon_manager.switch_weapon(1)
	elif event.is_action_pressed("slot_3"):
		weapon_manager.switch_weapon(2)
	elif event.is_action_pressed("slot_4"):
		weapon_manager.switch_weapon(3)
	
	# КОЛЕСИКО МЫШИ
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			weapon_manager.previous_weapon()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			weapon_manager.next_weapon()
	
	# ПЕРЕЗАРЯДКА
	if event.is_action_pressed("reload"):
		weapon_manager.reload()

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		_handle_local_player(delta)
	else:
		_handle_remote_player(delta)

func _handle_local_player(delta: float) -> void:
	if is_dead:
		return
	
	# ДВИЖЕНИЕ
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

	if anim_sprite.animation != current_animation:
		anim_sprite.play(current_animation)

	move_and_slide()

	# 🔫 ПРИЦЕЛИВАНИЕ И СТРЕЛЬБА
	_handle_aiming()
	_handle_shooting()

	_handle_stamina(delta)
	_check_auto_regen(delta)
	
	if hp_bar:
		hp_bar.value = int(health)
	if stamina_bar:
		stamina_bar.value = int(stamina)

	# СИНХРОНИЗАЦИЯ
	_sync_timer += delta
	if _sync_timer >= _sync_interval:
		_sync_timer = 0.0
		_sync_visual_state.rpc(global_position, current_animation, anim_sprite.flip_h, int(health))

func _handle_aiming() -> void:
	"""Прицеливание оружия на курсор"""
	if not gun_anchor:
		return
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - gun_anchor.global_position).normalized()
	
	# Поворот оружия
	gun_anchor.rotation = direction.angle()
	
	# Отражение спрайта
	var flip = mouse_pos.x < global_position.x
	anim_sprite.flip_h = flip
	
	if gun_sprite:
		gun_sprite.flip_v = flip
		# Корректировка позиции при отражении
		gun_sprite.offset.y = 2 if flip else -2

func _handle_shooting() -> void:
	"""Обработка стрельбы"""
	if not weapon_manager:
		return
	
	var current_weapon = weapon_manager.get_current_weapon()
	if not current_weapon:
		return
	
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - muzzle_point.global_position).normalized()
	
	# АВТОМАТИЧЕСКОЕ ОРУЖИЕ - зажатая кнопка
	if current_weapon.auto_fire:
		if Input.is_action_pressed("shoot"):
			weapon_manager.fire(direction)
			is_shooting = true
		else:
			weapon_manager.stop_firing()
			is_shooting = false
	# ОДИНОЧНОЕ ОРУЖИЕ - нажатие
	else:
		if Input.is_action_just_pressed("shoot"):
			weapon_manager.fire(direction)
			is_shooting = true
		elif Input.is_action_just_released("shoot"):
			is_shooting = false

@rpc("unreliable")
func _sync_visual_state(pos: Vector2, anim: String, flip: bool, hp: int) -> void:
	if is_multiplayer_authority():
		return
	
	_remote_position = pos
	_remote_animation = anim
	_remote_flip = flip
	
	if enemy_hp_bar:
		enemy_hp_bar.value = hp
		_update_hp_bar_color(hp)

func _update_hp_bar_color(hp: int) -> void:
	if not enemy_hp_bar:
		return
	
	var hp_percent = float(hp) / float(max_health)
	
	var color_high = Color(0.2, 1.0, 0.2)
	var color_mid = Color(1.0, 1.0, 0.2)
	var color_low = Color(1.0, 0.2, 0.2)
	
	var final_color: Color
	if hp_percent > 0.5:
		var t = (1.0 - hp_percent) * 2.0
		final_color = color_high.lerp(color_mid, t)
	else:
		var t = (0.5 - hp_percent) * 2.0
		final_color = color_mid.lerp(color_low, t)
	
	enemy_hp_bar.tint_progress = final_color

func _handle_remote_player(delta: float) -> void:
	global_position = global_position.lerp(_remote_position, 0.15)
	
	if anim_sprite.animation != _remote_animation:
		anim_sprite.animation = _remote_animation
		anim_sprite.play()
	
	if anim_sprite.flip_h != _remote_flip:
		anim_sprite.flip_h = _remote_flip

func take_damage(amount: float) -> void:
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
		_sync_death.rpc()
		return

	_set_invincible(true)
	await get_tree().create_timer(invincibility_time).timeout
	if not is_dead:
		_set_invincible(false)

@rpc("reliable")
func _sync_death() -> void:
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
	
	_sync_respawn.rpc()
	
	_set_invincible(true)
	await get_tree().create_timer(respawn_invincibility).timeout
	if not is_dead:
		_set_invincible(false)

	if anim_sprite:
		anim_sprite.play("idle")

@rpc("reliable")
func _sync_respawn() -> void:
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
