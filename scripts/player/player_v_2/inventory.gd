extends Node
class_name Inventory

signal inventory_updated
signal item_equipped(slot_index: int)

const MAX_SLOTS = 4
var slots: Array[Item] = []
var current_slot = 0

func _ready():
	# Инициализация пустых слотов
	slots.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		slots[i] = null

func add_item(item: Item, slot_index: int = -1) -> bool:
	# Если указан слот - добавить туда
	if slot_index >= 0 and slot_index < MAX_SLOTS:
		if slots[slot_index]:
			# Дроп старого предмета
			drop_item(slot_index)
		slots[slot_index] = item
		inventory_updated.emit()
		return true
	
	# Иначе найти первый свободный слот
	for i in range(MAX_SLOTS):
		if slots[i] == null:
			slots[i] = item
			inventory_updated.emit()
			return true
	
	return false  # Инвентарь полон

func remove_item(slot_index: int):
	if slot_index >= 0 and slot_index < MAX_SLOTS:
		slots[slot_index] = null
		inventory_updated.emit()

func get_item(slot_index: int) -> Item:
	if slot_index >= 0 and slot_index < MAX_SLOTS:
		return slots[slot_index]
	return null

func equip_slot(slot_index: int):
	if slot_index >= 0 and slot_index < MAX_SLOTS:
		current_slot = slot_index
		item_equipped.emit(slot_index)

func get_current_item() -> Item:
	return slots[current_slot]

func drop_item(slot_index: int):
	# TODO: Создать предмет в мире
	remove_item(slot_index)
