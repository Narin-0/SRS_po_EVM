extends Node2D

@onready var label = $Label

func _ready():
	# Анимация появления
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 50, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free).set_delay(1.0)

func set_damage(value: float):
	label.text = str(int(value))
