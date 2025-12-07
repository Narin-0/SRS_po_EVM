# ShotgunWeapon.gd
# Дробовик - выстрел веером + перезарядка
class_name ShotgunWeapon
extends WeaponSystem

@export var pellet_count: int = 8  # Количество дробинок
@export var spread_angle: float = 25.0  # Угол разброса (градусы)

func _init() -> void:
	weapon_name = "Shotgun"
	damage = 12.0
	fire_rate = 0.8
	energy_cost = 20.0
	projectile_speed = 650.0
	auto_fire = false
	max_ammo = 6
	reload_time = 2.5

func _spawn_projectile(direction: Vector2) -> void:
	"""Создаёт несколько снарядов веером"""
	if not projectile_scene or not muzzle_point:
		return
	
	var base_angle = direction.angle()
	var spread_rad = deg_to_rad(spread_angle)
	
	for i in range(pellet_count):
		# Равномерное распределение в пределах spread_angle
		var offset = lerp(-spread_rad / 2.0, spread_rad / 2.0, float(i) / float(pellet_count - 1))
		var pellet_direction = Vector2.from_angle(base_angle + offset)
		
		var projectile = projectile_scene.instantiate()
		get_tree().root.add_child(projectile)
		
		projectile.global_position = muzzle_point.global_position
		projectile.rotation = pellet_direction.angle()
		
		if projectile.has_method("setup"):
			projectile.setup(pellet_direction, projectile_speed, damage, player)
