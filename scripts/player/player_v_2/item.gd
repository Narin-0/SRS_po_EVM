extends Resource
class_name Item

enum ItemType {
	WEAPON_MELEE,
	WEAPON_RANGED,
	CONSUMABLE,
	MISC
}

enum Rarity {
	COMMON,
	RARE,
	LEGENDARY
}

@export var item_name: String = "Предмет"
@export var item_type: ItemType = ItemType.MISC
@export var icon: Texture2D
@export var rarity: Rarity = Rarity.COMMON
@export var max_stack: int = 1

# Виртуальные методы для переопределения
func use(player: CharacterBody2D):
	pass

func equip(player: CharacterBody2D):
	pass

func unequip(player: CharacterBody2D):
	pass
