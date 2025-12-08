# Projectile.gd
# Универсальный снаряд для всех видов оружия
extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var owner_player: CharacterBody2D = null
var lifetime: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Автоудаление через некоторое время
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(direction: Vector2, speed: float, dmg: float, player: CharacterBody2D) -> void:
	"""Настройка снаряда"""
	velocity = direction.normalized() * speed
	damage = dmg
	owner_player = player

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node) -> void:
	# Не попадаем в своего владельца
	if body == owner_player:
		return
	
	# Попадание в цель
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Попадание в Area2D (например, щиты)
	if area.owner == owner_player:
		return
	
	if area.has_method("take_damage"):
		area.take_damage(damage)
	
	queue_free()
