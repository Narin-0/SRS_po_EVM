# WeaponManager.gd
# Управление оружием, переключение, энергия
class_name WeaponManager
extends Node2D

# Энергия
@export var max_energy: float = 100.0
@export var energy_regen_rate: float = 15.0  # Восстановление в секунду
@export var energy_regen_delay: float = 1.0  # Задержка после стрельбы

var current_energy: float = 100.0
var energy_regen_timer: float = 0.0

# Оружие
var weapons: Array[WeaponSystem] = []
var current_weapon_index: int = 0
var current_weapon: WeaponSystem = null

# Ссылки
var player: CharacterBody2D
var muzzle_point: Marker2D
var weapon_sprite: Sprite2D

# UI
var energy_bar: TextureProgressBar
var ammo_label: Label
var weapon_name_label: Label

signal weapon_changed(weapon: WeaponSystem)
signal energy_changed(current: float, max_val: float)

func _ready() -> void:
	current_energy = max_energy

func setup(p: CharacterBody2D, muzzle: Marker2D, sprite: Sprite2D) -> void:
	"""Инициализация менеджера"""
	player = p
	muzzle_point = muzzle
	weapon_sprite = sprite
	
	# Находим UI элементы
	energy_bar = player.get_node_or_null("UI/EnergyBar")
	ammo_label = player.get_node_or_null("UI/AmmoLabel")
	weapon_name_label = player.get_node_or_null("UI/WeaponNameLabel")
	
	if energy_bar:
		energy_bar.max_value = max_energy
		energy_bar.value = current_energy
	
	# Скрываем оружие если нет активного
	if weapon_sprite and weapons.is_empty():
		weapon_sprite.visible = false

func add_weapon(weapon: WeaponSystem) -> void:
	"""Добавить оружие в инвентарь"""
	weapon.setup(player, muzzle_point, weapon_sprite)
	weapons.append(weapon)
	add_child(weapon)
	
	# Показываем спрайт оружия
	if weapon_sprite:
		weapon_sprite.visible = true
	
	# Активируем первое оружие
	if weapons.size() == 1:
		switch_weapon(0)

func has_weapon_type(weapon_type_name: String) -> bool:
	"""Проверка наличия оружия по имени"""
	for weapon in weapons:
		if weapon.weapon_name == weapon_type_name:
			return true
	return false

func get_weapon_count() -> int:
	"""Количество оружия в инвентаре"""
	return weapons.size()

func switch_weapon(index: int) -> void:
	"""Переключить оружие по индексу"""
	if index < 0 or index >= weapons.size():
		return
	
	if current_weapon == weapons[index]:
		return
	
	# Останавливаем лазер если был активен
	if current_weapon and current_weapon is LaserWeapon:
		current_weapon.stop_firing()
	
	current_weapon_index = index
	current_weapon = weapons[index]
	
	_update_weapon_sprite()
	_update_ui()
	weapon_changed.emit(current_weapon)

func next_weapon() -> void:
	"""Следующее оружие"""
	if weapons.is_empty():
		return
	var next_index = (current_weapon_index + 1) % weapons.size()
	switch_weapon(next_index)

func previous_weapon() -> void:
	"""Предыдущее оружие"""
	if weapons.is_empty():
		return
	var prev_index = (current_weapon_index - 1 + weapons.size()) % weapons.size()
	switch_weapon(prev_index)

func _process(delta: float) -> void:
	# Восстановление энергии
	if energy_regen_timer > 0:
		energy_regen_timer -= delta
	else:
		if current_energy < max_energy:
			current_energy += energy_regen_rate * delta
			current_energy = min(current_energy, max_energy)
			_update_energy_ui()

func fire(direction: Vector2) -> void:
	"""Стрельба из текущего оружия"""
	if not current_weapon:
		return
	
	var energy_spent = current_weapon.fire(direction, current_energy)
	
	if energy_spent > 0:
		current_energy -= energy_spent
		current_energy = max(0, current_energy)
		energy_regen_timer = energy_regen_delay
		_update_energy_ui()
		_update_ammo_ui()

func stop_firing() -> void:
	"""Остановить стрельбу (для лазера)"""
	if current_weapon and current_weapon is LaserWeapon:
		current_weapon.stop_firing()

func reload() -> void:
	"""Перезарядка текущего оружия"""
	if current_weapon:
		current_weapon.start_reload()

func get_current_weapon() -> WeaponSystem:
	return current_weapon

func _update_weapon_sprite() -> void:
	"""Обновить спрайт оружия"""
	if not weapon_sprite or not current_weapon:
		if weapon_sprite:
			weapon_sprite.visible = false
		return
	
	# Показываем и обновляем визуал текущего оружия
	weapon_sprite.visible = true
	current_weapon.update_weapon_visual()

func _update_ui() -> void:
	_update_energy_ui()
	_update_ammo_ui()
	_update_weapon_name()

func _update_energy_ui() -> void:
	if energy_bar:
		energy_bar.value = current_energy
	energy_changed.emit(current_energy, max_energy)

func _update_ammo_ui() -> void:
	if not ammo_label or not current_weapon:
		return
	
	var ammo_info = current_weapon.get_ammo_info()
	if ammo_info.infinite:
		ammo_label.text = "∞"
	else:
		ammo_label.text = "%d/%d" % [ammo_info.current, ammo_info.max]

func _update_weapon_name() -> void:
	if weapon_name_label and current_weapon:
		weapon_name_label.text = current_weapon.weapon_name
