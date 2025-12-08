extends Node2D
@export var max_health: int = 100
var current_health: int = 100

# Сигналы, которые будут отправляться
signal health_changed(new_health: int, max_health: int)
signal died

func _ready():
	current_health = max_health

func take_damage(amount: int):
	if amount <= 0: return
	current_health -= amount
	if current_health < 0:
		current_health = 0
	emit_signal("health_changed", current_health, max_health)
	if current_health == 0:
		emit_signal("died")

func heal(amount: int):
	if amount <= 0: return
	current_health += amount
	if current_health > max_health:
		current_health = max_health
	emit_signal("health_changed", current_health, max_health)
