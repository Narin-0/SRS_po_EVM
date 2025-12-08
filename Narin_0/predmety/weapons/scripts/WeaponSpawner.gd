# WeaponSpawner.gd
# Утилита для быстрого размещения оружия на карте
class_name WeaponSpawner
extends Node2D

@export var weapon_type: WeaponPickup.WeaponType = WeaponPickup.WeaponType.PISTOL
@export var auto_spawn: bool = true

var weapon_pickup_scene: PackedScene

func _ready() -> void:
	if auto_spawn:
		spawn_weapon()

func spawn_weapon() -> WeaponPickup:
	"""Создаёт pickup оружия"""
	var pickup = WeaponPickup.new()
	pickup.weapon_type = weapon_type
	pickup.global_position = global_position
	
	get_parent().add_child(pickup)
	
	return pickup

# Для использования в редакторе
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	var icon_text = ""
	match weapon_type:
		WeaponPickup.WeaponType.PISTOL:
			icon_text = "🔫 Pistol"
		WeaponPickup.WeaponType.MACHINEGUN:
			icon_text = "⚡ Machine Gun"
		WeaponPickup.WeaponType.SHOTGUN:
			icon_text = "💥 Shotgun"
		WeaponPickup.WeaponType.LASER:
			icon_text = "✨ Laser"
	
	warnings.append(icon_text + " spawner")
	return warnings
