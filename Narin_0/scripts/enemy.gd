extends CharacterBody2D

@export var speed: float = 60.0
@export var damage: float = 10.0
@export var touch_cooldown: float = 0.6

var anim_sprite: AnimatedSprite2D
var touchbox: Area2D
var _dir: Vector2 = Vector2.ZERO
var _state: String = "idle"
var _state_time: float = 0.0
var _cooldowns := {} # dictionary: player_id -> remaining time
var _rng: RandomNumberGenerator

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
	_update_state(delta)
	_update_movement(delta)
	_update_cooldowns(delta)


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
