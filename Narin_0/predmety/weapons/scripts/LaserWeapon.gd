# LaserWeapon.gd
# Лазер - непрерывный луч урона
class_name LaserWeapon
extends WeaponSystem

@export var laser_width: float = 3.0
@export var laser_max_length: float = 1000.0
@export var laser_color: Color = Color(1.0, 0.3, 0.3, 0.8)

var laser_line: Line2D
var is_firing: bool = false
var hit_particles: GPUParticles2D

func _init() -> void:
	weapon_name = "Laser"
	damage = 25.0  # Урон в секунду
	fire_rate = 0.05  # Частота проверки луча
	energy_cost = 15.0  # Энергия в секунду
	auto_fire = true
	max_ammo = -1  # Бесконечные патроны

func _ready() -> void:
	super._ready()
	_create_laser_line()

func _create_laser_line() -> void:
	"""Создаёт визуальную линию лазера"""
	laser_line = Line2D.new()
	laser_line.width = laser_width
	laser_line.default_color = laser_color
	laser_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	laser_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	laser_line.z_index = 10
	add_child(laser_line)
	
	# Добавляем эффект свечения
	laser_line.width_curve = Curve.new()
	laser_line.width_curve.add_point(Vector2(0, 1))
	laser_line.width_curve.add_point(Vector2(1, 0.5))

func fire(direction: Vector2, energy: float) -> float:
	"""Лазер работает непрерывно пока есть энергия"""
	if not can_fire(energy):
		stop_firing()
		return 0.0
	
	is_firing = true
	_update_laser(direction)
	
	can_shoot = false
	shoot_timer = fire_rate
	
	# Лазер тратит энергию непрерывно
	return energy_cost * fire_rate

func stop_firing() -> void:
	"""Остановить лазер"""
	is_firing = false
	if laser_line:
		laser_line.clear_points()

func _update_laser(direction: Vector2) -> void:
	"""Обновляет луч лазера и наносит урон"""
	if not muzzle_point or not laser_line:
		return
	
	var space_state = get_world_2d().direct_space_state
	var start = muzzle_point.global_position
	var end = start + direction * laser_max_length
	
	# Raycast для определения попадания
	var query = PhysicsRayQueryParameters2D.create(start, end)
	query.exclude = [player]  # Исключаем самого игрока
	query.collision_mask = 0b1011  # Враги + стены
	
	var result = space_state.intersect_ray(query)
	
	# Обновляем визуальную линию
	laser_line.clear_points()
	laser_line.add_point(to_local(start))
	
	if result:
		laser_line.add_point(to_local(result.position))
		
		# Наносим урон цели
		if result.collider.has_method("take_damage"):
			# Урон масштабируется по fire_rate (чтобы получился урон в секунду)
			result.collider.take_damage(damage * fire_rate)
	else:
		laser_line.add_point(to_local(end))

func _process(delta: float) -> void:
	super._process(delta)
	
	# Если не стреляем - скрываем луч
	if not is_firing and laser_line:
		laser_line.clear_points()

# Переопределяем метод - лазер не создаёт снаряды
func _spawn_projectile(direction: Vector2) -> void:
	pass
