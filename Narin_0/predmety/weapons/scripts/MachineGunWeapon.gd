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
