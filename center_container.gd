# CharacterSlot.gd
# Скрипт прикреплен к узлу CenterContainer
extends CenterContainer 

@export var character_id: String = ""
signal character_selected(id)

# 1. Ссылка на AnimatedSprite2D. Путь: $AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D

# 2. Ссылка на кнопку. Путь: $VBoxContainer/Button2
# Обратите внимание, что Button2 находится внутри VBoxContainer!
@onready var select_button = $VBoxContainer/Button2 
# Если Button2 — это узел для выбора:
# @onready var select_button = $VBoxContainer/Button2

func _ready():
	# --- ИСПРАВЛЕНИЕ ОШИБКИ 'Node not found: AnimatedSprite2D' ---
	# $AnimatedSprite2D.play("idle") теперь будет работать, 
	# так как AnimatedSprite2D находится на том же уровне, что и VBoxContainer
	
	if animated_sprite:
		# Запускаем анимацию 'idle'
		animated_sprite.play("default") 
	else:
		print("ОШИБКА: Узел AnimatedSprite2D не найден!")
		
	# Подключаем нажатие кнопки
	if select_button:
		select_button.pressed.connect(_on_select_button_pressed)
		
	# ДОПОЛНИТЕЛЬНО: Установка имени (если Label тоже нужно обновлять)
	# var name_label = $VBoxContainer/Label 
	# if name_label: 
	#     name_label.text = character_id.capitalize() # Или используйте данные из character_data

func _on_select_button_pressed():
	emit_signal("character_selected", character_id)
