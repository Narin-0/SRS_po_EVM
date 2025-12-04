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

@onready var gun_sprite = $GunAnchor/GunSprite2D

# 🌐 СЕТЕВЫЕ ПЕРЕМЕННЫЕ
var player_id: int = 0
var _sync_timer: float = 0.0
var _sync_interval: float = 0.1

# Переменные других игроков
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

	player_id = multiplayer.get_unique_id()
	_remote_position = global_position

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

	_handle_stamina(delta)
	_check_auto_regen(delta)

	# 🌐 СИНХРОНИЗАЦИЯ - отправляем данные каждые 0.1 сек
	_sync_timer += delta
	if _sync_timer >= _sync_interval:
		_sync_timer = 0.0
		_sync_player_state.rpc(global_position, current_animation, anim_sprite.flip_h, int(health), int(stamina))

@rpc("unreliable")
func _sync_player_state(pos: Vector2, anim: String, flip: bool, hp: int, stm: int) -> void:
	# Получаем данные от других игроков
	if is_multiplayer_authority():
		return
	
	_remote_position = pos
	_remote_animation = anim
	_remote_flip = flip
	
	if hp_bar:
		hp_bar.value = hp
	if stamina_bar:
		stamina_bar.value = stm

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
		return

	_set_invincible(true)
	await get_tree().create_timer(invincibility_time).timeout
	if not is_dead:
		_set_invincible(false)

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
	_set_invincible(true)
	await get_tree().create_timer(respawn_invincibility).timeout
	if not is_dead:
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
				stamina = min(stamina, float(max_stamina))

	if stamina_bar:
		stamina_bar.value = int(stamina)

func _check_auto_regen(delta: float) -> void:
	var target_hp = max_health * regen_target
	if health <= max_health * 0.5 and idle_time >= regen_delay and health < target_hp:
		if not is_regening:
			is_regening = true
		health += regen_speed * delta
		health = min(health, target_hp)
		if hp_bar:
			hp_bar.value = int(health)
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
