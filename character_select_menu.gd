extends Control

# --- 1. Данные о Персонажах ---
# Используйте Resource (или JSON) в реальном проекте.
# Для примера:
const CHARACTER_DATA = [
	{
		"id": "knight",
		"name": "Рыцарь",
		"sprite_path": "res://assets/sprites/knight_idle.tscn", # Сцена для персонажа (или просто спрайт)
		"info": "Стойкий воин с тяжелой броней.",
		"health": 200,
		"damage": 30
	},
	{
		"id": "vampire",
		"name": "Вампир",
		"sprite_path": "res://assets/sprites/vampire_idle.tscn", 
		"info": "Быстрый и смертоносный в темноте.",
		"health": 100,
		"damage": 50
	}
	# Добавьте больше персонажей
]

# --- 2. Ссылки на Узлы ---
@onready var character_list = $SelectionContainer/ScrollContainer/CharacterList
@onready var char_display_container = $CharDisplayContainer
@onready var label_name = $InfoPanel/Label
@onready var health_label = $InfoPanel/GridContainer/HealthLabel
@onready var damage_label = $InfoPanel/GridContainer/DamageLabel
@onready var description_label = $InfoPanel/DescriptionLabel
@onready var start_button = $StartButton

var current_char_scene: Node2D = null # Для хранения текущей сцены AnimatedSprite2D


# --- 3. Инициализация ---
func _ready():
	generate_char_buttons()
	# Выбираем первого персонажа при старте
	if not CHARACTER_DATA.is_empty():
		select_character(CHARACTER_DATA[0].id) 


# --- 4. Динамическое Создание Кнопок ---
func generate_char_buttons():
	for char_data in CHARACTER_DATA:
		# Создаем кнопку (предполагаем, что CharButton.tscn - это ваша кнопка с иконкой)
		var button = Button.new() # Используем Button, но можно использовать TextureButton
		button.text = char_data.name.left(1) # Используем первую букву как иконку
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Сохраняем ID персонажа в метаданных кнопки (ВАЖНО!)
		button.set_meta("char_id", char_data.id) 
		
		# Подключаем сигнал нажатия
		button.pressed.connect(_on_char_button_pressed.bind(char_data.id))
		
		character_list.add_child(button)


# --- 5. Основная Логика Выбора ---
func select_character(char_id: String):
	var selected_data = find_character_data(char_id)
	if selected_data == null: return
	
	# 5.1. Обновление Главного Дисплея (AnimatedSprite2D)
	
	# Удаляем старого персонажа
	if current_char_scene:
		current_char_scene.queue_free()
	
	# Загружаем новую сцену персонажа (Knight/Vampire)
	var new_char_scene_res = load(selected_data.sprite_path)
	if new_char_scene_res:
		current_char_scene = new_char_scene_res.instantiate()
		# Помещаем его в контейнер отображения
		char_display_container.add_child(current_char_scene)
		# Убедитесь, что его позиция сброшена или центрирована
		current_char_scene.position = Vector2.ZERO 
	
	# 5.2. Обновление InfoPanel (Характеристики)
	label_name.text = selected_data.name
	description_label.text = selected_data.info
	health_label.text = "HP: " + str(selected_data.health)
	damage_label.text = "DMG: " + str(selected_data.damage)
	
	# Здесь можно добавить логику сохранения выбранного ID в Autoload


# --- 6. Обработчики Сигналов ---

func _on_char_button_pressed(char_id: String):
	select_character(char_id)
	
func _on_start_button_pressed():
	# Проверка и переход к игре
	print("Начать игру с выбранным персонажем!")
	
	
# --- 7. Вспомогательная Функция ---
func find_character_data(char_id: String):
	for char_data in CHARACTER_DATA:
		if char_data.id == char_id:
			return char_data
	return null
