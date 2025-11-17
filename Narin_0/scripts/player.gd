extends CharacterBody2D

signal health_changed(new_health)
signal died
signal regen_started
signal regen_stopped

@export var walk_speed: float = 100.0
@export var run_speed: float = 200.0
@export var max_health: int = 100
@export var invincibility_time: float = 1.5
@export var regen_delay: float = 15.0
@export var regen_speed: float = 80.0
@export var regen_target: float = 0.7
@export var regen_glow_intensity: float = 0.5

# stamina
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

@onready var gun_sprite = $GunAnchor/GunSprite2D

# 🌐 НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ МУЛЬТИПЛЕЕРА
var player_id: int = 0
var _last_sync_position: Vector2 = Vector2.ZERO
var _sync_interval: float = 0.1
var _sync_timer: float = 0.0


func _ready() -> void:
	anim_sprite = $AnimatedSprite2D
	hp_bar = $UI/HPBar
	stamina_bar = get_node_or_null("UI/StaminaBar")
	
	if not is_instance_valid(gun_sprite):
		push_error("⚠️ GunSprite2D не найден!")
		
	_original_modulate = modulate

	add_to_group("player")

	health = clamp(float(max_health), 0.0, float(max_health))

	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = int(health)
	else:
		push_error("⚠️ HPBar не найден!")

	stamina = float(max_stamina)
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = int(stamina)
	else:
		push_error("⚠️ StaminaBar не найден!")

	_spawn_position = global_position

	death_menu = get_node_or_null("UI/DeathMenu")
	if death_menu:
		var resp_btn = death_menu.get_node_or_null("RespawnButton")
		var quit_btn = death_menu.get_node_or_null("QuitButton")
		if resp_btn:
			resp_btn.pressed.connect(Callable(self, "_on_respawn_pressed"))
		if quit_btn:
			quit_btn.pressed.connect(Callable(self, "_on_quit_pressed"))
		if death_menu.has_method("hide"):
			death_menu.hide()

	var cam = $Camera2D
	cam.enabled = is_multiplayer_authority()  # Камера только для хозяина
	if cam.enabled:
		cam.make_current()
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 5.0

	# 🌐 Инициализируем player_id
	player_id = multiplayer.get_unique_id()


func _input(event):
	if not is_multiplayer_authority():
		return
		
	if event.is_action_pressed("ui_right"):
		$Inventory.next_item()
	elif event.is_action_pressed("ui_left"):
		$Inventory.previous_item()


func _physics_process(delta: float) -> void:
	# Только хозяин обрабатывает ввод
	if not is_multiplayer_authority():
		return

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

	if input_vector == Vector2.ZERO:
		anim_sprite.play("idle")
		idle_time += delta
	else:
		idle_time = 0.0
		if _is_sprinting:
			anim_sprite.play("run")
		else:
			anim_sprite.play("walking")

		if input_vector.x != 0:
			anim_sprite.flip_h = input_vector.x < 0

	move_and_slide()

	if is_instance_valid(gun_sprite):
		var mouse_x = get_global_mouse_position().x
		
		if mouse_x < global_position.x:
			anim_sprite.flip_h = true
			gun_sprite.flip_h = true
		else:
			anim_sprite.flip_h = false
			gun_sprite.flip_h = false
		
		gun_sprite.rotation = 0

	_handle_stamina(delta)
	_check_auto_regen(delta)

	# 🌐 СИНХРОНИЗАЦИЯ ПОЗИЦИИ
	_sync_timer += delta
	if _sync_timer >= _sync_interval:
		_sync_timer = 0.0
		if global_position.distance_to(_last_sync_position) > 5.0:
			_last_sync_position = global_position
			print("📡 Отправка позиции: %s (ID: %d)" % [global_position, player_id])
			_sync_player_position.rpc(global_position, anim_sprite.animation, anim_sprite.flip_h)


@rpc("unreliable")
func _sync_player_position(new_pos: Vector2, anim_name: String, flip: bool) -> void:
	if is_multiplayer_authority():
		return
	
	print("📍 Получена позиция: %s от игрока %d" % [new_pos, get_multiplayer_authority()])
	global_position = new_pos
	if anim_sprite:
		anim_sprite.animation = anim_name
		anim_sprite.flip_h = flip


func take_damage(amount: float) -> void:
	print("💥 Урон получен: %.0f (текущее HP: %.0f)" % [amount, health])
	
	if is_invincible or is_dead:
		print("⚠️ Игрок неуязвим или мертв!")
		return

	health -= amount
	if health < 0:
		health = 0
	if hp_bar:
		hp_bar.value = int(health)
	emit_signal("health_changed", health)

	_flash_white()

	if health <= 0:
		print("💀 Игрок мертв!")
		is_dead = true
		emit_signal("died")
		_on_death()
		_sync_player_death.rpc()
		return

	_set_invincible(true)
	await get_tree().create_timer(invincibility_time).timeout
	_set_invincible(false)


@rpc("call_local")
func _sync_player_death() -> void:
	# Все видят смерть игрока
	pass


func _on_death() -> void:
	velocity = Vector2.ZERO
	call_deferred("set_physics_process", false)
	call_deferred("set_process", false)

	if is_in_group("player"):
		remove_from_group("player")

	var cs = get_node_or_null("CollisionShape2D")
	if cs:
		cs.set_deferred("disabled", true)

	if anim_sprite:
		anim_sprite.play("death")

	await get_tree().create_timer(0.05).timeout

	if death_menu and is_multiplayer_authority():
		if death_menu.has_method("popup_centered"):
			death_menu.popup_centered()
		else:
			death_menu.visible = true


func _on_respawn_pressed() -> void:
	if death_menu:
		if death_menu.has_method("hide"):
			death_menu.hide()
		else:
			death_menu.visible = false

	health = float(max_health)
	stamina = float(max_stamina)
	if hp_bar:
		hp_bar.value = int(health)
	if stamina_bar:
		stamina_bar.value = int(stamina)

	global_position = _spawn_position

	if not is_in_group("player"):
		add_to_group("player")

	set_physics_process(true)
	set_process(true)
	var cs = get_node_or_null("CollisionShape2D")
	if cs:
		cs.disabled = false

	is_dead = false
	_set_invincible(true)
	await get_tree().create_timer(respawn_invincibility).timeout
	_set_invincible(false)

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
				if stamina > max_stamina:
					stamina = max_stamina

	if stamina_bar:
		stamina_bar.value = int(stamina)


func _check_auto_regen(delta: float) -> void:
	var target_hp = max_health * regen_target
	if health <= max_health * 0.5 and idle_time >= regen_delay and health < target_hp:
		if not is_regening:
			is_regening = true
			emit_signal("regen_started")
		health += regen_speed * delta
		if health > target_hp:
			health = target_hp
		if hp_bar:
			hp_bar.value = int(health)
		emit_signal("health_changed", health)
		_apply_regen_glow(delta)
	else:
		if is_regening:
			anim_sprite.modulate = _original_modulate
			is_regening = false
			emit_signal("regen_stopped")


func _apply_regen_glow(_delta: float) -> void:
	var glow_strength = regen_glow_intensity * (0.5 + 0.5 * sin(Time.get_ticks_msec() / 300.0))
	anim_sprite.modulate = Color(1 - glow_strength, 1, 1 - glow_strength, 1)


func _flash_white() -> void:
	var prev = anim_sprite.modulate if anim_sprite else modulate
	if anim_sprite:
		anim_sprite.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.15).timeout

	for i in range(5):
		if anim_sprite:
			anim_sprite.visible = false
		await get_tree().create_timer(0.1).timeout
		if anim_sprite:
			anim_sprite.visible = true
		await get_tree().create_timer(0.1).timeout

	if anim_sprite:
		anim_sprite.modulate = prev
	else:
		modulate = prev


func _set_invincible(state: bool) -> void:
	is_invincible = state
	if state:
		modulate = Color(_original_modulate.r, _original_modulate.g, _original_modulate.b, 0.6)
	else:
		modulate = _original_modulate
