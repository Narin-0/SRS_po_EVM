extends Item
class_name GunItem

@export var damage: float = 15.0
@export var bullet_speed: float = 400.0
@export var fire_rate: float = 0.3
@export var bullet_scene: PackedScene

var can_shoot = true

func use(player: CharacterBody2D):
	if can_shoot:
		shoot(player)
		can_shoot = false
		await player.get_tree().create_timer(fire_rate).timeout
		can_shoot = true

func shoot(player: CharacterBody2D):
	if not bullet_scene:
		return
	
	var bullet = bullet_scene.instantiate()
	player.get_parent().add_child(bullet)
	
	bullet.global_position = player.global_position
	var direction = (player.get_global_mouse_position() - player.global_position).normalized()
	bullet.direction = direction
	bullet.speed = bullet_speed
	bullet.damage = damage
