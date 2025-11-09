extends Area2D

@export var item: Item

@onready var sprite = $Sprite2D
@onready var label = $Label

func _ready():
	if item:
		sprite.texture = item.icon
		label.text = item.item_name
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_node("Inventory"):
			var inventory = body.get_node("Inventory")
			if inventory.add_item(item):
				queue_free()  # Удалить подбираемый предмет
