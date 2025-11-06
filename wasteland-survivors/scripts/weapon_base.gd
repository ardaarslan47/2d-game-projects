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
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0  # In degrees
@export var pierce_count: int = 0
@export var weapon_range: float = 300.0  # Maximum range to target enemies
@export var projectile_scene: PackedScene

# Public variables
var owner_node: Node2D  # Set by WeaponManager when weapon is added

# Private variables
var _fire_cooldown: float = 0.0
var _can_fire: bool = true

func _ready() -> void:
	# Validate owner_node is set
	assert(owner_node != null, "WeaponBase: owner_node must be set by WeaponManager before _ready()")

	if not projectile_scene:
		# Default projectile
		projectile_scene = load("res://scenes/weapons/projectile.tscn")

func _process(delta: float) -> void:
	# Handle cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
		if _fire_cooldown <= 0:
			_can_fire = true

	# Auto-fire if enabled
	if _can_fire:
		fire()

# Public methods
func fire() -> void:
	if not _can_fire:
		return

	_can_fire = false
	_fire_cooldown = 1.0 / fire_rate

	# Find nearest enemy
	var target_direction: Vector2 = _find_target_direction()
	if target_direction == Vector2.ZERO:
		return  # No target found

	# Spawn projectiles
	for i in range(projectile_count):
		_spawn_projectile(target_direction, i)

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
func _find_target_direction() -> Vector2:
	# Find nearest enemy within weapon range
	var enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	if enemies.is_empty() or not owner_node:
		return Vector2.ZERO

	var owner_pos: Vector2 = owner_node.global_position
	var nearest_enemy: Node = null
	var nearest_distance: float = INF

	for enemy in enemies:
		var distance: float = owner_pos.distance_to(enemy.global_position)

		# Only consider enemies within weapon range
		if distance <= weapon_range and distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy

	if nearest_enemy:
		return owner_pos.direction_to(nearest_enemy.global_position)

	return Vector2.ZERO

func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	if not projectile_scene or not owner_node:
		return

	var projectile: Projectile = projectile_scene.instantiate()

	# Calculate spread
	var angle_offset: float = 0.0
	if projectile_count > 1 and spread_angle > 0:
		var spread_step: float = spread_angle / (projectile_count - 1)
		angle_offset = -spread_angle / 2.0 + spread_step * index

	var direction: Vector2 = base_direction.rotated(deg_to_rad(angle_offset))

	# Add to scene
	get_tree().current_scene.add_child(projectile)

	# Setup projectile
	projectile.setup(owner_node.global_position, direction, damage)
	projectile.speed = projectile_speed
	projectile.pierce_count = pierce_count
