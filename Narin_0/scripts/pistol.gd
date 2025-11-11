extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.18            # секунды между выстрелами
@export var bullet_speed: float = 900.0
@export var bullet_damage: float = 20.0
@export var muzzle_node_path: NodePath = NodePath("")  # оставьте пустым и назначьте в инспекторе, или найдём автоматически

var _muzzle: Node2D = null
var _fire_timer: Timer = null
var _can_shoot: bool = true

func _ready() -> void:
	# 1) если задан путь в инспекторе — пробуем взять по нему
	if muzzle_node_path != NodePath(""):
		_muzzle = get_node_or_null(muzzle_node_path) as Node2D
	# 2) если не нашли — рекурсивно ищем узел с именем, содержащим "muzzle"
	if not _muzzle:
		_muzzle = _find_muzzle_recursive(self)
	# 3) если всё ещё не найден — возьмём первый Marker2D / Node2D-ребёнок
	if not _muzzle:
		for c in get_children():
			if c is Marker2D or c is Node2D:
				_muzzle = c as Node2D
				break

	if not _muzzle:
		push_warning("Pistol.gd: Muzzle (Marker2D / Node2D) not found. Назначьте в Muzzle Node Path или переименуйте узел в 'muzzle'.")
	else:
		print("Pistol: found muzzle =", _muzzle, "at", _muzzle.get_path())

	# таймер перезарядки (повторно используемый)
	_fire_timer = Timer.new()
	_fire_timer.one_shot = true
	add_child(_fire_timer)
	_fire_timer.timeout.connect(Callable(self, "_on_fire_cooldown"))


# вспомогательная рекурсивная функция
func _find_muzzle_recursive(n: Node) -> Node2D:
	for c in n.get_children():
		if c is Node:
			var name_l = c.name.to_lower()
			if name_l.find("muzzle") != -1 and (c is Marker2D or c is Node2D):
				return c as Node2D
			var found = _find_muzzle_recursive(c)
			if found:
				return found
	return null


func _process(_delta: float) -> void:
	# поворачиваем оружие в сторону курсора
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - global_position
	if dir.length() > 0.001:
		rotation = dir.angle()

	# стрельба при удержании кнопки
	if Input.is_action_pressed("shoot"):
		_shoot()


func _shoot() -> void:
	if not _can_shoot:
		return
	if not bullet_scene:
		push_error("Pistol.gd: bullet_scene не назначен")
		return

	var muzzle_global = _muzzle.global_position if _muzzle else global_position
	# DEBUG: покажем координаты, чтобы убедиться, откуда стреляем
	print("Pistol: muzzle =", _muzzle, "muzzle_global =", muzzle_global)

	var dir = (get_global_mouse_position() - muzzle_global)
	if dir.length() == 0:
		return
	dir = dir.normalized()

	# инстансим пулю и инициализируем
	var bullet = bullet_scene.instantiate()
	if bullet.has_method("init"):
		bullet.init(dir, bullet_speed, bullet_damage, get_parent()) # owner = игрок (родитель Pistol)
	bullet.global_position = muzzle_global
	get_tree().get_current_scene().add_child(bullet)

	# устанавливаем кулдаун
	_can_shoot = false
	_fire_timer.start(fire_rate)


func _on_fire_cooldown() -> void:
	_can_shoot = true
