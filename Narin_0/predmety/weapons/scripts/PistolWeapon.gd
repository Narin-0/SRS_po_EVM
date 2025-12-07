# PistolWeapon.gd
# Пистолет - одиночные выстрелы
class_name PistolWeapon
extends WeaponSystem

func _init() -> void:
	weapon_name = "Pistol"
	damage = 15.0
	fire_rate = 0.3
	energy_cost = 8.0
	projectile_speed = 700.0
	auto_fire = false
	max_ammo = 12
	reload_time = 1.2
