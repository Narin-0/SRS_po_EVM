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
@export var stamina_depletion_rate: float = 25.0   # единиц в секунду при беге
@export var stamina_regen_rate: float = 20.0       # единиц в секунду при регене
@export var stamina_regen_delay: float = 1.2       # сек после прекращения бега перед регеном

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

# внутренние для стамины
var _stamina_regen_timer: float = 0.0
var _is_sprinting: bool = false

# death / respawn
var death_menu: Control
var _spawn_position: Vector2
@export var respawn_invincibility: float = 1.2  # краткая неуязвимость после респауна

func _ready() -> void:
	anim_sprite = $AnimatedSprite2D
	hp_bar = $UI/HPBar
	stamina_bar = get_node_or_null("UI/StaminaBar")

	_original_modulate = modulate

	# Добавляем в группу, чтобы проще находили игрока из других скриптов
	add_to_group("player")

	# Инициализируем здоровье
	health = clamp(float(max_health), 0.0, float(max_health))

	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = int(health)
	else:
		push_error("⚠️ HPBar не найден! Проверь путь $UI/HPBar")

	# Инициализируем стамину и UI
	stamina = float(max_stamina)
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = int(stamina)
	else:
		push_error("⚠️ StaminaBar не найден! Добавьте TextureProgressBar в UI с именем 'StaminaBar' по пути $UI/StaminaBar")

	# запоминаем начальную позицию для респауна
	_spawn_position = global_position

	# пытаемся найти меню смерти в UI: UI/DeathMenu
	death_menu = get_node_or_null("UI/DeathMenu")
	if death_menu:
		# подключаем кнопки если есть
		var resp_btn = death_menu.get_node_or_null("RespawnButton")
		var quit_btn = death_menu.get_node_or_null("QuitButton")
		if resp_btn:
			resp_btn.pressed.connect(Callable(self, "_on_respawn_pressed"))
		if quit_btn:
			quit_btn.pressed.connect(Callable(self, "_on_quit_pressed"))
		# скрываем меню при старте
		if death_menu.has_method("hide"):
			death_menu.hide()
	else:
		# если меню нет — просто предупреждаем (далее можно динамически создавать)
		push_warning("⚠️ UI/DeathMenu не найден. Создайте Control UI/DeathMenu с кнопками RespawnButton и QuitButton для меню смерти.")

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

	# управление бегом с учётом стамины
	var run_pressed = Input.is_action_pressed("run")
	# бег возможен только при движении и если есть стамина > 0
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

	# обработка затрат/регенерации стамины
	_handle_stamina(delta)

	_check_auto_regen(delta)


func _handle_stamina(delta: float) -> void:
	if _is_sprinting:
		# уменьшаем стамину
		stamina -= stamina_depletion_rate * delta
		_stamina_regen_timer = 0.0
		if stamina <= 0.0:
			stamina = 0.0
			_is_sprinting = false
	else:
		# если не бежим — считаем время до начала регена
		_stamina_regen_timer += delta
		if _stamina_regen_timer >= stamina_regen_delay:
			if stamina < max_stamina:
				stamina += stamina_regen_rate * delta
				if stamina > max_stamina:
					stamina = max_stamina

	# обновляем UI
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


func take_damage(amount: float) -> void:
	if is_invincible or is_dead:
		return

	health -= amount
	if health < 0:
		health = 0
	if hp_bar:
		hp_bar.value = int(health)
	emit_signal("health_changed", health)

	_flash_white()

	# Если здоровье закончилось — запускаем логику смерти
	if health <= 0:
		is_dead = true
		emit_signal("died")
		_on_death()
		return

	_set_invincible(true)
	await get_tree().create_timer(invincibility_time).timeout
	_set_invincible(false)


func _on_death() -> void:
	# Останавливаем движение сразу (отложенно отключаем обработку, чтобы не ломать физику)
	velocity = Vector2.ZERO
	call_deferred("set_physics_process", false)
	call_deferred("set_process", false)

	# удаляем игрока из группы, чтобы враги его не видели пока мёртв
	if is_in_group("player"):
		remove_from_group("player")

	# Отключаем коллизию отложенно
	var cs = get_node_or_null("CollisionShape2D")
	if cs:
		cs.set_deferred("disabled", true)

	# Запускаем анимацию смерти (если есть)
	if anim_sprite:
		anim_sprite.play("death")

	# даём 0.05 секунды анимации чтобы она стартовала и отрисовалась, затем показываем меню
	await get_tree().create_timer(0.05).timeout

	# Показываем меню смерти сразу (без ожидания окончания анимации)
	if death_menu:
		if death_menu.has_method("popup_centered"):
			death_menu.popup_centered()
		else:
			death_menu.visible = true
	else:
		# fallback: если меню не создано, просто перезагрузим текущую сцену через 2 секунды
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()


func _on_respawn_pressed() -> void:
	# скрываем меню
	if death_menu:
		if death_menu.has_method("hide"):
			death_menu.hide()
		else:
			death_menu.visible = false

	# восстановление состояния
	health = float(max_health)
	stamina = float(max_stamina)
	if hp_bar:
		hp_bar.value = int(health)
	if stamina_bar:
		stamina_bar.value = int(stamina)

	# возвращаем позицию (спавн)
	global_position = _spawn_position

	# возвращаем игрока в группу, включаем физику/обработку и коллизию
	if not is_in_group("player"):
		add_to_group("player")

	set_physics_process(true)
	set_process(true)
	var cs = get_node_or_null("CollisionShape2D")
	if cs:
		cs.disabled = false

	# небольшой эффект/неуязвимость после респауна
	is_dead = false
	_set_invincible(true)
	await get_tree().create_timer(respawn_invincibility).timeout
	_set_invincible(false)

	# анимация встать
	if anim_sprite:
		anim_sprite.play("idle")


func _on_quit_pressed() -> void:
	# выход из игры
	get_tree().quit()

# Добавлены отсутствующие helper-функции, которые вызывались в коде выше
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
		# делаем персонажа полупрозрачным, сохраняя цвет
		modulate = Color(_original_modulate.r, _original_modulate.g, _original_modulate.b, 0.6)
	else:
		modulate = _original_modulate
