class_name WeaponProjectile
extends WeaponBaseNew

## Base class for projectile-based weapons.
## Handles projectile spawning, multi-shot, and targeting.

# Projectile-specific exports
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var projectile_count: int = 1  # Number of projectiles per shot
@export var multi_shot_delay: float = 0.05  # Delay between shots (0 = simultaneous)
@export var projectile_spread_angle: float = 0.0  # Spread angle in degrees for multi-shot
@export var pierce_count: int = 0
@export var projectile_size_multiplier: float = 1.0
@export var projectile_pool: ProjectilePool  # Optional object pool

# Upgrade bonuses
var pierce_bonus: int = 0
var projectile_count_bonus: int = 0

# Private variables
var _multi_shot_queue: Array[Dictionary] = []  # Queue of {direction: Vector2, index: int}
var _multi_shot_timer: float = 0.0

# Computed properties
var total_projectile_count: int:
	get: return projectile_count + projectile_count_bonus

func _on_weapon_ready() -> void:
	if not projectile_scene:
		projectile_scene = load("res://scenes/weapons/projectile.tscn")

func _process_weapon(delta: float) -> void:
	# Handle multi-shot queue
	if _multi_shot_queue.size() > 0:
		_multi_shot_timer -= delta
		if _multi_shot_timer <= 0:
			var shot_data: Dictionary = _multi_shot_queue.pop_front()
			_spawn_projectile(shot_data.direction, shot_data.index)
			_multi_shot_timer = multi_shot_delay

func _execute_fire() -> void:
	# Get target directions (override this method for different targeting modes)
	var target_directions: Array[Vector2] = _get_target_directions()
	if target_directions.is_empty():
		return

	# Queue up shots
	_multi_shot_queue.clear()
	for i in range(target_directions.size()):
		_multi_shot_queue.append({
			"direction": target_directions[i],
			"index": i
		})
	_multi_shot_timer = 0.0  # Fire first shot immediately

## Virtual Methods (override for different targeting modes)

func _get_target_directions() -> Array[Vector2]:
	"""Get directions to fire projectiles. Override for different targeting modes.
	Default: auto-target nearest enemies."""
	return _get_auto_target_directions(total_projectile_count)

func _get_auto_target_directions(count: int) -> Array[Vector2]:
	"""Find directions to multiple nearest enemies."""
	var enemies: Array[Node] = get_enemies_in_range()
	if enemies.is_empty():
		return []

	var owner_pos: Vector2 = get_owner_position()
	var target_directions: Array[Vector2] = []

	# Sort enemies by distance
	var sorted_enemies: Array[Dictionary] = []
	for enemy in enemies:
		sorted_enemies.append({
			"enemy": enemy,
			"distance": owner_pos.distance_to(enemy.global_position)
		})
	sorted_enemies.sort_custom(func(a, b): return a.distance < b.distance)

	# Get directions to nearest enemies (wrap around if more shots than enemies)
	for i in range(count):
		var target_index: int = i % sorted_enemies.size()
		var enemy: Node = sorted_enemies[target_index].enemy
		var direction: Vector2 = owner_pos.direction_to(enemy.global_position)
		target_directions.append(direction)

	return target_directions

func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	"""Spawn a projectile in the given direction."""
	var projectile: Projectile

	# Use object pool if available
	if projectile_pool:
		projectile = projectile_pool.get_projectile()
	elif projectile_scene:
		projectile = projectile_scene.instantiate()
		get_tree().current_scene.call_deferred("add_child", projectile)
	else:
		push_error("WeaponProjectile: No projectile_pool or projectile_scene for " + weapon_name)
		return

	# Apply spread angle if multi-shot
	var final_direction: Vector2 = base_direction
	if projectile_spread_angle > 0 and total_projectile_count > 1:
		var angle_offset: float = _calculate_spread_offset(index, total_projectile_count)
		final_direction = base_direction.rotated(deg_to_rad(angle_offset))

	# Setup projectile
	var final_damage: int = int(damage)
	projectile.setup(get_owner_position(), final_direction, final_damage)
	projectile.speed = projectile_speed
	projectile.pierce_count = pierce_count + pierce_bonus

	# Apply size multiplier
	if projectile.has_method("set_size_multiplier"):
		projectile.set_size_multiplier(projectile_size_multiplier)
	else:
		projectile.scale = Vector2.ONE * projectile_size_multiplier

func _calculate_spread_offset(index: int, total_count: int) -> float:
	"""Calculate spread angle offset for a projectile index."""
	if total_count == 1:
		return 0.0

	# Distribute projectiles evenly across spread angle
	var half_spread: float = projectile_spread_angle / 2.0
	var step: float = projectile_spread_angle / (total_count - 1) if total_count > 1 else 0.0
	return -half_spread + (step * index)

## Override upgrade method for projectile-specific stats

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Pierce":
			pierce_bonus += int(multiplier)
		"Multi-Shot":
			projectile_count_bonus += int(multiplier)
		"Projectile Size":
			projectile_size_multiplier *= multiplier
		"Projectile Speed":
			projectile_speed *= multiplier
		"Spread Angle":
			projectile_spread_angle *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
