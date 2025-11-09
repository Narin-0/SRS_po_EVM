extends CanvasLayer

@onready var hp_bar = $MarginContainer/VBoxContainer/HPBar
@onready var stamina_bar = $MarginContainer/VBoxContainer/StaminaBar

var player: CharacterBody2D

func _ready():
	# Найти игрока
	player = get_tree().get_first_node_in_group("player")
	if player:
		hp_bar.max_value = player.max_hp
		stamina_bar.max_value = player.max_stamina

func _process(_delta):
	if player:
		hp_bar.value = player.current_hp
		stamina_bar.value = player.current_stamina
