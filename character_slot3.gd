extends Control

# Путь к HBoxContainer, содержащему всех персонажей
# Убедитесь, что этот путь ($ScrollContainer/HBoxContainer) точен в дереве сцены!
@onready var character_container = $ScrollContainer/HBoxContainer

# ИСПРАВЛЕНО: Загружаем SCENE (.tscn), а не скрипт (.gd)
const CharacterSlotScene = preload("res://character_slot.tscn") 

# Массив данных о персонажах
var character_data = [
	{"id": "knight", "name": "Рыцарь"},
	{"id": "mage", "name": "Маг"},
	{"id": "archer", "name": "Лучник"},
]

func _ready():
	_populate_character_slots()

func _populate_character_slots():
	for data in character_data:
		# Создаем новый экземпляр СЦЕНЫ
		var char_slot = CharacterSlotScene.instantiate()
		
		# Устанавливаем уникальный ID для этого слота
		char_slot.character_id = data.id
		
		# Подключаем сигнал char_slot (он должен быть объявлен в CharacterSlot.gd)
		if char_slot.has_signal("character_selected"):
			char_slot.character_selected.connect(_on_character_slot_selected)
		else:
			print("Ошибка: Слот персонажа не имеет сигнала 'character_selected'.")
		
		# Добавляем его в HBoxContainer
		character_container.add_child(char_slot)
		
# Функция-обработчик, которая вызывается при выборе персонажа
func _on_character_slot_selected(id: String):
	print("Выбран персонаж с ID: ", id)
	
	# Здесь код для сохранения выбора и перехода на другую сцену:
	# Global.selected_character_id = id
	# get_tree().change_scene_to_file("res://game_world.tscn")
