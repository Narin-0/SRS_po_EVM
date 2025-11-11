extends CharacterBody2D

@export var speed: float = 60.0
@export var damage: float = 10.0
@export var touch_cooldown: float = 0.6

# sight / chase
@export var sight_radius: float = 100.0
@export var chase_speed_multiplier: float = 1.4
@export var lose_sight_time: float = 1.5   # seconds to forget player after leaving sight

var anim_sprite: AnimatedSprite2D
var touchbox: Area2D
var _dir: Vector2 = Vector2.ZERO
var _state: String = "idle"                 # "idle", "walk", "chase"
var _state_time: float = 0.0
var _cooldowns := {}                        # dictionary: target_id -> remaining time
var _rng: RandomNumberGenerator
var _target: Node = null
var _lose_timer: float = 0.0

func _ready():
	# найдём AnimatedSprite2D (по имени или первый попавшийся)
	anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite:
		for c in get_children():
			if c is AnimatedSprite2D:
				anim_sprite = c
				break
	if not anim_sprite:
		push_error("Enemy.gd: AnimatedSprite2D not found. Add an AnimatedSprite2D child.")

	# безопасно ищем Area2D TouchBox (рекомендуемое имя) или первый Area2D
	touchbox = get_node_or_null("TouchBox")
	if not touchbox:
		for c in get_children():
			if c is Area2D:
				touchbox = c
				break

	if touchbox:
		if touchbox.has_signal("body_entered"):
			touchbox.body_entered.connect(Callable(self, "_on_touchbox_body_entered"))
		else:
			push_error("Enemy.gd: Area2D found but it has no 'body_entered' signal.")
	else:
		push_error("Enemy.gd: TouchBox (Area2D) not found. Add an Area2D child named 'TouchBox' with a CollisionShape2D.")

	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_state = "idle"
	_state_time = _rng.randf_range(0.5, 2.0)


func _physics_process(delta: float) -> void:
	# если есть цель — управляем преследованием отдельно
	if _target and is_instance_valid(_target):
		_chase_update(delta)
	else:
		# пытаемся обнаружить игрока
		var found = _detect_player()
		if found:
			_target = found
			_state = "chase"
			_lose_timer = 0.0
		else:
			_update_state(delta)
			_update_movement(delta)

	_update_cooldowns(delta)


func _detect_player() -> Node:
	var nodes = get_tree().get_nodes_in_group("player")
	var best: Node = null
	var best_dist = INF
	for p in nodes:
		if not is_instance_valid(p):
			continue

		# Если объект имеет флаг is_dead — пропускаем (без ошибок, даже если свойства нет)
		var dead_val = p.get("is_dead")
		if dead_val != null and bool(dead_val):
			continue

		# Убедимся, что объект задаёт позицию (обычно Node2D / CharacterBody2D)
		if not (p is Node2D):
			continue

		var d = global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p

	if best and best_dist <= sight_radius:
		return best
	return null


func _chase_update(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = null
		_state = "idle"
		return

	# Если цель помечена как мёртвая — прекращаем преследование (без ошибок, даже если свойства нет)
	var dead_val = _target.get("is_dead")
	if dead_val != null and bool(dead_val):
		_target = null
		_state = "idle"
		return

	var dist = global_position.distance_to(_target.global_position)
	# если игрок вышел за радиус — начинаем таймер потери цели
	if dist > sight_radius:
		_lose_timer += delta
		if _lose_timer >= lose_sight_time:
			_target = null
			_state = "idle"
			_lose_timer = 0.0
			return
	else:
		_lose_timer = 0.0

	# движение к цели
	_dir = (_target.global_position - global_position).normalized()
	velocity = _dir * speed * chase_speed_multiplier
	if anim_sprite:
		anim_sprite.flip_h = _dir.x < 0
		anim_sprite.play("walking")
	move_and_slide()


func _update_state(delta: float) -> void:
	_state_time -= delta
	if _state == "idle" and _state_time <= 0.0:
		_state = "walk"
		_state_time = _rng.randf_range(1.0, 3.0)
		var angle = _rng.randf() * TAU
		_dir = Vector2(cos(angle), sin(angle)).normalized()
		if anim_sprite:
			anim_sprite.play("walking")
	elif _state == "walk" and _state_time <= 0.0:
		_state = "idle"
		_state_time = _rng.randf_range(0.5, 2.0)
		_dir = Vector2.ZERO
		if anim_sprite:
			anim_sprite.play("idle")


func _update_movement(_delta: float) -> void:
	if _dir != Vector2.ZERO:
		velocity = _dir * speed
		if anim_sprite:
			anim_sprite.flip_h = _dir.x < 0
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _on_touchbox_body_entered(body) -> void:
	# Если у объекта есть метод take_damage — атакуем его
	if body and body.has_method("take_damage"):
		var id = str(body.get_instance_id())
		if _cooldowns.has(id) and _cooldowns[id] > 0.0:
			return
		body.take_damage(damage)
		_cooldowns[id] = touch_cooldown


func _update_cooldowns(delta: float) -> void:
	var keys := _cooldowns.keys()
	for k in keys:
		_cooldowns[k] -= delta
		if _cooldowns[k] <= 0.0:
			_cooldowns.erase(k)
