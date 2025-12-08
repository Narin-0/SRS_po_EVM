extends Control

# Путь к HBoxContainer, содержащему всех персонажей
@onready var character_container = $ScrollContainer/HBoxContainer

# Сюда вы будете загружать сцену персонажа для инстанцирования
const CharacterSlotScene = preload("res://character_slot.tscn") 

# Массив данных о персонажах (можно загрузить из JSON/базы данных)
var character_data = [
	{"id": "knight", "name": "Рыцарь"},
	{"id": "mage", "name": "Маг"},
	{"id": "archer", "name": "Лучник"},
]

func _ready():
	# Создаем слоты персонажей при запуске
	_populate_character_slots()

func _populate_character_slots():
	for data in character_data:
		# Создаем новый экземпляр сцены
		var char_slot = CharacterSlotScene.instantiate()
		
		# Устанавливаем уникальный ID для этого слота
		char_slot.character_id = data.id
		
		# Подключаем сигнал char_slot к функции в этом скрипте
		char_slot.character_selected.connect(_on_character_slot_selected)
		
		# Добавляем его в HBoxContainer
		character_container.add_child(char_slot)
		
		# 💡 Дополнительно: здесь можно обновить Label с именем персонажа.

# Функция-обработчик, которая вызывается при выборе персонажа
func _on_character_slot_selected(id: String):
	print("Выбран персонаж с ID: ", id)
	
	# 1. Сохраните выбор (например, в глобальном скрипте Autoload)
	# Global.selected_character_id = id
	
	# 2. Перейдите на следующую сцену
	# get_tree().change_scene_to_file("res://game_world.tscn")
	pass
