extends CharacterBody2D

@export var speed: float = 1000.0
@export var damage: float = 20.0
@export var life_time: float = 3.0
var _vel: Vector2 = Vector2.ZERO
var _owner: Object = null

func _ready() -> void:
	# авто-удаление через таймер
	if life_time > 0.0:
		var t = Timer.new()
		t.one_shot = true
		t.wait_time = life_time
		add_child(t)
		t.start()
		t.timeout.connect(Callable(self, "_on_life_timeout"))

func init(direction: Vector2, p_speed: float, p_damage: float, owner: Node = null) -> void:
	_vel = direction.normalized() * p_speed
	speed = p_speed
	damage = p_damage
	_owner = owner
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if _vel == Vector2.ZERO:
		return
	var collision = move_and_collide(_vel * delta)
	if collision:
		var collider = collision.get_collider()
		# не наносим себе
		if collider and collider != _owner:
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
		queue_free()

func _on_life_timeout() -> void:
	queue_free()
