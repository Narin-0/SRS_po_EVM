extends Item
class_name SwordItem

@export var damage: float = 25.0
@export var attack_range: float = 50.0
@export var attack_speed: float = 1.0

func use(player: CharacterBody2D):
	# Ближняя атака
	perform_melee_attack(player)

func perform_melee_attack(player: CharacterBody2D):
	var mouse_pos = player.get_global_mouse_position()
	var attack_direction = (mouse_pos - player.global_position).normalized()
	
	# Создание зоны атаки
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	query.shape = shape
	query.transform = Transform2D(0, player.global_position + attack_direction * attack_range)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)
