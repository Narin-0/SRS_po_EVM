extends CanvasLayer

@onready var health_bar = $HealthBar
@onready var stamina_bar = $StaminaBar
@onready var slots = [$InventoryUI/Slot1, $InventoryUI/Slot2, 
					  $InventoryUI/Slot3, $InventoryUI/Slot4]

var player: CharacterBody2D

func _ready():
	player = get_parent()  # Или используйте get_node()

func _process(_delta):
	if player:
		health_bar.value = player.current_health / player.max_health * 100
		stamina_bar.value = player.current_stamina / player.max_stamina * 100
		update_inventory_ui()

func update_inventory_ui():
	for i in range(4):
		if player.inventory[i] != null:
			slots[i].texture = player.inventory[i].texture
		else:
			slots[i].texture = null
		
		# Подсветка текущего слота
		if i == player.current_slot:
			slots[i].modulate = Color(1, 1, 0)  # Жёлтый
		else:
			slots[i].modulate = Color(1, 1, 1)  # Белый
