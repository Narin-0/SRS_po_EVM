# WeaponSystem.gd
# Базовый класс для всех типов оружия
class_name WeaponSystem
extends Node2D

# Статистика оружия
@export var weapon_name: String = "Weapon"
@export var damage: float = 10.0
@export var fire_rate: float = 0.2  # Время между выстрелами
@export var energy_cost: float = 10.0  # Энергия за выстрел
@export var projectile_speed: float = 600.0
@export var auto_fire: bool = false  # Автоматическая стрельба
@export var max_ammo: int = -1  # -1 = бесконечные патроны
@export var reload_time: float = 1.5

# Сцена снаряда
@export var projectile_scene: PackedScene

# Внутренние переменные
var current_ammo: int = 0
var can_shoot: bool = true
var is_reloading: bool = false
var shoot_timer: float = 0.0

# Ссылки
var player: CharacterBody2D
var muzzle_point: Marker2D

signal ammo_changed(current: int, max_ammo: int)
signal weapon_fired()
signal reload_started()
signal reload_finished()

func _ready() -> void:
	if max_ammo > 0:
		current_ammo = max_ammo

func _process(delta: float) -> void:
	if shoot_timer > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true

func setup(p: CharacterBody2D, muzzle: Marker2D) -> void:
	"""Инициализация оружия"""
	player = p
	muzzle_point = muzzle

func can_fire(energy: float) -> bool:
	"""Проверка возможности стрельбы"""
	if is_reloading or not can_shoot:
		return false
	
	if energy < energy_cost:
		return false
	
	if max_ammo > 0 and current_ammo <= 0:
		start_reload()
		return false
	
	return true

func fire(direction: Vector2, energy: float) -> float:
	"""Выстрел, возвращает потраченную энергию"""
	if not can_fire(energy):
		return 0.0
	
	_spawn_projectile(direction)
	
	# Расход патронов и энергии
	if max_ammo > 0:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, max_ammo)
	
	can_shoot = false
	shoot_timer = fire_rate
	weapon_fired.emit()
	
	return energy_cost

func _spawn_projectile(direction: Vector2) -> void:
	"""Создание снаряда (переопределяется в наследниках)"""
	if not projectile_scene or not muzzle_point:
		return
	
	var projectile = projectile_scene.instantiate()
	get_tree().root.add_child(projectile)
	
	projectile.global_position = muzzle_point.global_position
	projectile.rotation = direction.angle()
	
	if projectile.has_method("setup"):
		projectile.setup(direction, projectile_speed, damage, player)

func start_reload() -> void:
	"""Начать перезарядку"""
	if is_reloading or max_ammo < 0 or current_ammo >= max_ammo:
		return
	
	is_reloading = true
	can_shoot = false
	reload_started.emit()
	
	await get_tree().create_timer(reload_time).timeout
	
	current_ammo = max_ammo
	is_reloading = false
	can_shoot = true
	reload_finished.emit()
	ammo_changed.emit(current_ammo, max_ammo)

func get_ammo_info() -> Dictionary:
	"""Информация о патронах"""
	return {
		"current": current_ammo,
		"max": max_ammo,
		"infinite": max_ammo < 0
	}
