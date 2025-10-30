extends Node

# Список предметов (Texture2D)
var items: Array = []
var selected_index: int = -1

# Ссылка на спрайт предмета, который висит рядом с персонажем
@export var item_sprite_path: NodePath
var item_sprite: Sprite2D

func _ready():
	item_sprite = get_node(item_sprite_path)
	if item_sprite_path == NodePath(""):
		item_sprite_path = "../InventoryHolder/ItemSprite"
	item_sprite = get_node(item_sprite_path)

func add_item(item_texture: Texture2D):
	items.append(item_texture)
	if selected_index == -1:
		selected_index = 0
	update_held_item()

func remove_item(index: int):
	if index >= 0 and index < items.size():
		items.remove_at(index)
		if selected_index >= items.size():
			selected_index = items.size() - 1
		update_held_item()

func select_item(index: int):
	if items.size() == 0:
		selected_index = -1
	elif index >= 0 and index < items.size():
		selected_index = index
	update_held_item()

func next_item():
	if items.size() > 0:
		selected_index = (selected_index + 1) % items.size()
		update_held_item()

func previous_item():
	if items.size() > 0:
		selected_index = (selected_index - 1 + items.size()) % items.size()
		update_held_item()

func update_held_item():
	if selected_index == -1 or items.size() == 0:
		item_sprite.visible = false
	else:
		item_sprite.texture = items[selected_index]
		item_sprite.visible = true
