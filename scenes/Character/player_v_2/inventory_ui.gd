extends CanvasLayer

@onready var slots = [
	$HBoxContainer/Slot1,
	$HBoxContainer/Slot2,
	$HBoxContainer/Slot3,
	$HBoxContainer/Slot4
]

var inventory: Inventory

func _ready():
	# Получить инвентарь игрока
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Inventory"):
		inventory = player.get_node("Inventory")
		inventory.inventory_updated.connect(_on_inventory_updated)
		inventory.item_equipped.connect(_on_item_equipped)
	
	update_ui()

func _process(_delta):
	# Обработка переключения слотов
	if Input.is_action_just_pressed("slot_1"):
		inventory.equip_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		inventory.equip_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		inventory.equip_slot(2)
	elif Input.is_action_just_pressed("slot_4"):
		inventory.equip_slot(3)

func _on_inventory_updated():
	update_ui()

func _on_item_equipped(slot_index: int):
	update_ui()
	highlight_slot(slot_index)

func update_ui():
	if not inventory:
		return
	
	for i in range(4):
		var item = inventory.get_item(i)
		var icon = slots[i].get_node("TextureRect")
		
		if item:
			icon.texture = item.icon
			icon.visible = true
		else:
			icon.visible = false

func highlight_slot(slot_index: int):
	for i in range(4):
		if i == slot_index:
			slots[i].modulate = Color(1.5, 1.5, 1.0)  # Подсветка
		else:
			slots[i].modulate = Color(1.0, 1.0, 1.0)
