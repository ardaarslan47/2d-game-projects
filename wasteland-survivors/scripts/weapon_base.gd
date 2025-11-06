class_name WeaponBase
extends Node2D

## Base class for all weapons.
## Handles automatic firing, cooldowns, and projectile spawning.

# Signals
signal fired

# Exported variables
@export var weapon_name: String = "Weapon"
@export var damage: int = 10
@export var fire_rate: float = 1.0  # Shots per second
@export var projectile_speed: float = 400.0
@export var projectile_count: int = 1  # Number of different targets to shoot at once
@export var multi_shot_delay: float = 0.05  # Delay between each shot in multi-shot
@export var pierce_count: int = 0
@export var weapon_range: float = 300.0  # Maximum range to target enemies
@export var projectile_scene: PackedScene
@export var projectile_size_multiplier: float = 1.0  # Size multiplier for projectiles
@export var projectile_pool: ProjectilePool  # Object pool for projectiles (optional, improves performance)

# Public variables
var owner_node: Node2D  # Set by WeaponManager when weapon is added

# Upgrade multipliers (set by player)
var fire_rate_multiplier: float = 1.0
var damage_multiplier: float = 1.0
var pierce_bonus: int = 0

# Private variables
var _fire_cooldown: float = 0.0
var _can_fire: bool = true
var _multi_shot_queue: Array[Vector2] = []  # Queue of target directions for multi-shot
var _multi_shot_timer: float = 0.0

func _ready() -> void:
	# Validate owner_node is set
	assert(owner_node != null, "WeaponBase: owner_node must be set by WeaponManager before _ready()")

	if not projectile_scene:
		# Default projectile
		projectile_scene = load("res://scenes/weapons/projectile.tscn")

func _process(delta: float) -> void:
	# Handle fire cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
		if _fire_cooldown <= 0:
			_can_fire = true

	# Handle multi-shot queue
	if _multi_shot_queue.size() > 0:
		_multi_shot_timer -= delta
		if _multi_shot_timer <= 0:
			var direction: Vector2 = _multi_shot_queue.pop_front()
			_spawn_projectile(direction, 0)
			_multi_shot_timer = multi_shot_delay

	# Auto-fire if enabled and queue is empty
	if _can_fire and _multi_shot_queue.is_empty():
		fire()

# Public methods
func fire() -> void:
	if not _can_fire:
		return

	_can_fire = false
	# Apply fire rate multiplier
	_fire_cooldown = 1.0 / (fire_rate * fire_rate_multiplier)

	# Find multiple target directions (one per projectile_count)
	var target_directions: Array[Vector2] = _find_multiple_target_directions(projectile_count)
	if target_directions.is_empty():
		return  # No targets found

	# Queue up the shots with delays
	_multi_shot_queue = target_directions.duplicate()
	_multi_shot_timer = 0.0  # Fire first shot immediately

	fired.emit()

func upgrade_damage(amount: int) -> void:
	damage += amount

func upgrade_fire_rate(multiplier: float) -> void:
	fire_rate *= multiplier

func upgrade_projectile_count(amount: int) -> void:
	projectile_count += amount

func upgrade_range(amount: float) -> void:
	weapon_range += amount

# Private methods
func _find_multiple_target_directions(count: int) -> Array[Vector2]:
	"""Find directions to multiple nearest enemies.
	Returns array of directions, can target same enemy multiple times if not enough enemies."""
	var enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	if enemies.is_empty() or not owner_node:
		return []

	var owner_pos: Vector2 = owner_node.global_position
	var target_directions: Array[Vector2] = []

	# Get all enemies within range with their distances
	var enemies_in_range: Array[Dictionary] = []
	for enemy in enemies:
		var distance: float = owner_pos.distance_to(enemy.global_position)
		if distance <= weapon_range:
			enemies_in_range.append({
				"enemy": enemy,
				"distance": distance
			})

	if enemies_in_range.is_empty():
		return []

	# Sort by distance (closest first)
	enemies_in_range.sort_custom(func(a, b): return a.distance < b.distance)

	# Get directions to nearest enemies
	# If we need more shots than enemies, target nearest enemy multiple times
	for i in range(count):
		var target_index: int = i % enemies_in_range.size()  # Wrap around if needed
		var enemy: Node = enemies_in_range[target_index].enemy
		var direction: Vector2 = owner_pos.direction_to(enemy.global_position)
		target_directions.append(direction)

	return target_directions

func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	if not owner_node:
		return

	var projectile: Projectile

	# Use object pool if available, otherwise instantiate directly
	if projectile_pool:
		projectile = projectile_pool.get_projectile()
	elif projectile_scene:
		projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
	else:
		push_error("WeaponBase: No projectile_pool or projectile_scene configured for " + weapon_name)
		return

	# Setup projectile with multipliers applied
	var final_damage: int = int(damage * damage_multiplier)
	projectile.setup(owner_node.global_position, base_direction, final_damage)
	projectile.speed = projectile_speed
	projectile.pierce_count = pierce_count + pierce_bonus

	# Apply size multiplier
	if projectile.has_method("set_size_multiplier"):
		projectile.set_size_multiplier(projectile_size_multiplier)
	else:
		# Fallback: directly scale the projectile
		projectile.scale = Vector2.ONE * projectile_size_multiplier
