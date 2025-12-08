extends CharacterBody2D
@export var default_speed: float = 100.0
@export var jump_velocity: float = -400.0 # Для платформеров
@export var gravity: float = 1000.0 # Для платформеров

# --- Ссылки на дочерние узлы ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Node = $HealthComponent
@onready var stats_component: Node = $StatsComponent

# --- Приватные переменные для движения ---
var current_speed: float = default_speed
var current_direction: Vector2 = Vector2.ZERO # Для 2D движения

func _ready():
	if health_component:
		health_component.connect("died", _on_died)
		health_component.connect("health_changed", _on_health_changed)
	
	if stats_component:
		# Обновляем скорость, используя stat_component
		current_speed = stats_component.get_stat_value("move_speed")

func _physics_process(delta):
	# Пример логики движения (для 2D шутера с видом сверху)
	# Если это платформер, здесь будет логика прыжков и гравитации
	
	# current_direction устанавливается через _input или извне
	velocity = current_direction * current_speed
	move_and_slide() # Godot 4: move_and_slide() больше не возвращает velocity

	# Обновление анимации
	update_animation()

func update_animation():
	if animated_sprite:
		if current_direction.x != 0:
			animated_sprite.flip_h = current_direction.x < 0
			animated_sprite.play("run")
		elif current_direction.y != 0: # Для 2D сверху вниз
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

# --- ОБЩИЕ ФУНКЦИИ ---
func take_damage(amount: int):
	if health_component:
		health_component.take_damage(amount)

func heal(amount: int):
	if health_component:
		health_component.heal(amount)

func get_current_health() -> int:
	return health_component.current_health if health_component else 0

func get_max_health() -> int:
	return health_component.max_health if health_component else 0

# --- Сигналы HealthComponent ---
func _on_health_changed(new_health: int, max_health: int):
	print("Здоровье изменилось: ", new_health, "/", max_health)
	# Здесь можно обновить UI над головой персонажа

func _on_died():
	print("Персонаж умер!")
	# Здесь можно запустить анимацию смерти, уничтожить персонажа, и т.д.
	queue_free() # Пример: удалить узел
