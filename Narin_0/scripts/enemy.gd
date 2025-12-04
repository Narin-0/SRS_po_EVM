extends CharacterBody2D

@export var speed: float = 60.0
@export var damage: float = 10.0
@export var touch_cooldown: float = 0.6
@export var sight_radius: float = 100.0
@export var chase_speed_multiplier: float = 1.4
@export var lose_sight_time: float = 1.5

var anim_sprite: AnimatedSprite2D
var touchbox: Area2D
var _dir: Vector2 = Vector2.ZERO
var _state: String = "idle"
var _state_time: float = 0.0
var _cooldowns: Dictionary = {}
var _rng: RandomNumberGenerator
var _target: Node = null
var _lose_timer: float = 0.0

func _ready() -> void:
	anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite:
		for c in get_children():
			if c is AnimatedSprite2D:
				anim_sprite = c
				break
	
	var tb = get_node_or_null("TouchBox")
	if not tb:
		tb = get_node_or_null("Area2D")
	
	touchbox = tb as Area2D
	if touchbox:
		touchbox.body_entered.connect(Callable(self, "_on_touchbox_body_entered"))
	
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_state = "idle"
	_state_time = _rng.randf_range(0.5, 2.0)

func _physics_process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var dead = _target.get("is_dead")
		if dead != null and bool(dead):
			_target = null
			_state = "idle"
		else:
			_chase_update(delta)
	else:
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
	var best: Node = null
	var best_dist = INF
	for p in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(p):
			continue
		var dead = p.get("is_dead")
		if dead != null and bool(dead):
			continue
		var d = global_position.distance_to(p.global_position)
		if d < best_dist:
			best_dist = d
			best = p
	
	return best if best and best_dist <= sight_radius else null

func _chase_update(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = null
		_state = "idle"
		return
	
	var dist = global_position.distance_to(_target.global_position)
	if dist > sight_radius:
		_lose_timer += delta
		if _lose_timer >= lose_sight_time:
			_target = null
			_state = "idle"
			_lose_timer = 0.0
			return
	else:
		_lose_timer = 0.0

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
		_dir = Vector2(cos(_rng.randf() * TAU), sin(_rng.randf() * TAU))
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
	if body and body.has_method("take_damage"):
		var id = str(body.get_instance_id())
		if _cooldowns.get(id, 0.0) > 0.0:
			return
		body.take_damage(damage)
		_cooldowns[id] = touch_cooldown

func _update_cooldowns(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] -= delta
		if _cooldowns[key] <= 0.0:
			_cooldowns.erase(key)
