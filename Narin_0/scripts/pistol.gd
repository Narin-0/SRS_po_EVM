extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.18
@export var bullet_speed: float = 900.0
@export var bullet_damage: float = 20.0

var _muzzle: Node2D = null
var _fire_timer: Timer = null
var _can_shoot: bool = true

func _ready() -> void:
	_muzzle = get_node_or_null("Marker2D")
	if not _muzzle:
		for c in get_children():
			if c is Marker2D:
				_muzzle = c
				break
	
	_fire_timer = Timer.new()
	_fire_timer.one_shot = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(Callable(self, "_on_fire_cooldown"))

func _process(_delta: float) -> void:
	var parent = get_parent().get_parent()
	if not parent:
		return
	
	var mouse_pos = get_global_mouse_position()
	var parent_pos = parent.global_position
	var dir = mouse_pos - parent_pos
	if dir.length() > 0.001:
		parent.rotation = dir.angle()
	
	if Input.is_action_pressed("shoot"):
		_shoot()

func _shoot() -> void:
	if not _can_shoot or not bullet_scene:
		return
	
	var muzzle_pos = _muzzle.global_position if _muzzle else global_position
	var direction = (get_global_mouse_position() - muzzle_pos).normalized()
	
	_fire_bullet(muzzle_pos, direction, bullet_speed, bullet_damage)
	
	_can_shoot = false
	_fire_timer.start(fire_rate)

func _fire_bullet(muzzle_pos: Vector2, direction: Vector2, speed: float, dmg: float) -> void:
	var bullet = bullet_scene.instantiate()
	if bullet.has_method("init"):
		bullet.init(direction, speed, dmg, get_parent().get_parent())
	bullet.global_position = muzzle_pos
	get_tree().get_current_scene().add_child(bullet)

func _on_fire_cooldown() -> void:
	_can_shoot = true
