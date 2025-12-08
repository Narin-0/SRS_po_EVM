# WeaponPickup.gd
# Подбираемое оружие на карте
class_name WeaponPickup
extends Area2D

# Тип оружия для создания
enum WeaponType {
	PISTOL,
	MACHINEGUN,
	SHOTGUN,
	LASER
}

@export var weapon_type: WeaponType = WeaponType.PISTOL
@export var bob_height: float = 5.0  # Высота левитации
@export var bob_speed: float = 2.0   # Скорость левитации
@export var rotation_speed: float = 1.0  # Скорость вращения

var sprite: Sprite2D
var collision: CollisionShape2D
var time: float = 0.0
var initial_y: float = 0.0
var can_pickup: bool = true

# Данные оружия для отображения
var weapon_data: Dictionary = {
	WeaponType.PISTOL: {
		"name": "Pistol",
		"color": Color(0.7, 0.7, 0.7),
		"size": Vector2(20, 8)
	},
	WeaponType.MACHINEGUN: {
		"name": "Machine Gun",
		"color": Color(0.4, 0.4, 0.4),
		"size": Vector2(30, 8)
	},
	WeaponType.SHOTGUN: {
		"name": "Shotgun",
		"color": Color(0.6, 0.4, 0.2),
		"size": Vector2(25, 10)
	},
	WeaponType.LASER: {
		"name": "Laser",
		"color": Color(0.2, 0.6, 1.0),
		"size": Vector2(28, 4)
	}
}

signal weapon_picked_up(weapon_type: WeaponType, pickup: WeaponPickup)

func _ready() -> void:
	_create_visual()
	_create_collision()
	
	initial_y = position.y
	
	body_entered.connect(_on_body_entered)
	
	# Настройка коллизий
	collision_layer = 16  # Layer 5 для pickups
	collision_mask = 4    # Mask для игрока (layer 3)

func _create_visual() -> void:
	"""Создаёт визуал оружия"""
	sprite = Sprite2D.new()
	add_child(sprite)
	
	var data = weapon_data[weapon_type]
	var size = data.size
	var color = data.color
	
	# Создаём простую текстуру оружия
	var img = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	
	# Добавляем обводку
	for x in range(int(size.x)):
		img.set_pixel(x, 0, Color.BLACK)
		img.set_pixel(x, int(size.y) - 1, Color.BLACK)
	for y in range(int(size.y)):
		img.set_pixel(0, y, Color.BLACK)
		img.set_pixel(int(size.x) - 1, y, Color.BLACK)
	
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.z_index = 1
	
	# Добавляем свечение
	var glow = Sprite2D.new()
	glow.texture = sprite.texture
	glow.modulate = Color(color.r, color.g, color.b, 0.3)
	glow.scale = Vector2(1.2, 1.2)
	glow.z_index = 0
	sprite.add_child(glow)
	
	# Анимация свечения
	var tween = create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.5, 1.0)
	tween.tween_property(glow, "modulate:a", 0.1, 1.0)

func _create_collision() -> void:
	"""Создаёт область подбора"""
	collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 25.0  # Радиус подбора
	collision.shape = shape
	add_child(collision)

func _process(delta: float) -> void:
	time += delta
	
	# Эффект левитации
	position.y = initial_y + sin(time * bob_speed) * bob_height
	
	# Вращение
	sprite.rotation += rotation_speed * delta

func _on_body_entered(body: Node2D) -> void:
	"""Обработка подбора оружия"""
	if not can_pickup:
		return
	
	if body.is_in_group("player") and body.has_method("pickup_weapon"):
		# Проверяем authority для мультиплеера
		if body.has_method("is_multiplayer_authority"):
			if not body.is_multiplayer_authority():
				return
		
		body.pickup_weapon(weapon_type)
		weapon_picked_up.emit(weapon_type, self)
		
		# Эффект подбора
		_play_pickup_effect()
		
		# Удаляем pickup
		can_pickup = false
		await get_tree().create_timer(0.3).timeout
		queue_free()

func _play_pickup_effect() -> void:
	"""Визуальный эффект подбора"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "position:y", position.y - 30, 0.3)

func get_weapon_instance() -> WeaponSystem:
	"""Создаёт экземпляр оружия для добавления в инвентарь"""
	var weapon: WeaponSystem = null
	
	match weapon_type:
		WeaponType.PISTOL:
			weapon = PistolWeapon.new()
		WeaponType.MACHINEGUN:
			weapon = MachineGunWeapon.new()
		WeaponType.SHOTGUN:
			weapon = ShotgunWeapon.new()
		WeaponType.LASER:
			weapon = LaserWeapon.new()
	
	return weapon
