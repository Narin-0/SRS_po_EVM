extends Node2D
@export var move_speed: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_rate: float = 1.0 # Атак в секунду

# Пример получения характеристики
func get_stat_value(stat_name: String) -> float:
	match stat_name:
		"move_speed": return move_speed
		"attack_damage": return attack_damage
		"attack_rate": return attack_rate
	return 0.0 # Если характеристика не найдена
