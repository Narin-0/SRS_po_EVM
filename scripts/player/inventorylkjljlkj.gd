extends Node

# Список предметов (Texture2D)
var items: Array = []
var selected_index: int = -1

@export var grid_path: NodePath
@export var item_sprite_path: NodePath

var grid: GridContainer
var item_sprite: Sprite2D


func _ready():
	# Получаем UI контейнер с панелями
	if grid_path == NodePath(""):
		grid_path = "../UI/GridContainer"
		push_error("grid_path не задан в инспекторе")
	else:
		grid = get_node(grid_path)
	# Спрайт у игрока
	if item_sprite_path == NodePath(""):
		item_sprite_path = "../InventoryHolder/ItemSprite"
	item_sprite = get_node(item_sprite_path)

	update_ui()
	update_held_item()


# -------------------------
# ДОБАВЛЕНИЕ ПРЕДМЕТА
# -------------------------
func add_item(item_texture: Texture2D) -> void:
	items.append(item_texture)

	# Если первый предмет — выбираем его
	if selected_index == -1:
		selected_index = 0

	update_ui()
	update_held_item()


# -------------------------
# ВЫБОР СЛОТА ПО КЛАВИШАМ
# -------------------------
func _input(event):
	if event.is_action_pressed("slot_1"):
		select_item(0)
	if event.is_action_pressed("slot_2"):
		select_item(1)
	if event.is_action_pressed("slot_3"):
		select_item(2)
	if event.is_action_pressed("slot_4"):
		select_item(3)


func select_item(index: int) -> void:
	if items.size() == 0:
		selected_index = -1
	elif index >= 0 and index < items.size():
		selected_index = index

	update_ui()
	update_held_item()


# -------------------------
# ОБНОВЛЕНИЕ ИКОНКИ У ПЕРСОНАЖА
# -------------------------
func update_held_item() -> void:
	if item_sprite == null:
		return

	if selected_index == -1 or items.size() == 0:
		item_sprite.visible = false
		return

	item_sprite.texture = items[selected_index]
	item_sprite.visible = true


# -------------------------
# ОБНОВЛЕНИЕ ИКОНОК В UI GRIDCONTAINER
# -------------------------
func update_ui() -> void:
	if grid == null:
		return

	for i in range(grid.get_child_count()):
		var panel := grid.get_child(i)
		if panel == null:
			continue

		# Ищем TextureRect внутри панели. Имя должно быть "TextureRect"
		if not panel.has_node("TextureRect"):
			continue
		var tex: TextureRect = panel.get_node("TextureRect")

		# Устанавливаем текстуру если предмет есть
		if i < items.size():
			tex.texture = items[i]
		else:
			tex.texture = null

		# Подсветка выбранного (исправлена тернарная конструкция)
		panel.modulate = Color(1, 1, 1) if i == selected_index else Color(0.7, 0.7, 0.7)
