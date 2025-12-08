# MachineGunWeapon.gd
# Пулемёт - автоматическая стрельба
class_name MachineGunWeapon
extends WeaponSystem

func _init() -> void:
	weapon_name = "Machine Gun"
	damage = 8.0
	fire_rate = 0.08
	energy_cost = 4.0
	projectile_speed = 800.0
	auto_fire = true
	max_ammo = 50
	reload_time = 2.0
	
	# Визуал
	weapon_color = Color(0.4, 0.4, 0.4)  # Тёмно-серый
	weapon_offset = Vector2(0, -2)

func _get_default_size() -> Vector2:
	return Vector2(30, 8)
