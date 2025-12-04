extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 900.0
var damage: float = 20.0
var shooter: Node = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func init(dir: Vector2, spd: float, dmg: float, shoot: Node) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	shooter = shoot

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area == shooter:
		return
	
	if area.is_in_group("enemy"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()
	elif area.is_in_group("player") and area != shooter:
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()
