class_name EnemySpawner
extends Node2D

## Spawns enemies in waves around the player.
## Uses object pooling for performance.

# Exported variables
@export var spawn_interval: float = 1.0
@export var spawn_distance: float = 600.0
@export var max_enemies: int = 50
@export var enemy_pool: EnemyPool  # Object pool for enemies (optional, improves performance)

# Private variables
var _spawn_timer: float = 0.0
var _zombie_scene: PackedScene
var _zombie_cat_scene: PackedScene

# Onready variables
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	_zombie_scene = load("res://scenes/enemies/zombie.tscn")
	_zombie_cat_scene = load("res://scenes/enemies/zombie_cat.tscn")

func _process(delta: float) -> void:
	_spawn_timer -= delta

	if _spawn_timer <= 0:
		# Apply difficulty scaling: faster spawn rate over time
		var spawn_rate_multiplier: float = GameManager.get_spawn_rate_multiplier()
		_spawn_timer = spawn_interval / spawn_rate_multiplier
		_spawn_enemy()

# Private methods
func _spawn_enemy() -> void:
	# Check enemy limit
	var current_enemies := get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_enemies:
		return

	# Determine which enemy type to spawn based on game time
	if _is_zombie_cat_window():
		_spawn_zombie_cat_pack()
	else:
		_spawn_single_zombie()

func _is_zombie_cat_window() -> bool:
	"""Check if current game time is in a zombie cat spawn window.
	Windows: 1:00-1:30, 3:00-3:30, 5:00-5:30, etc. (every 2 minutes for 30 seconds)"""
	var game_time: float = GameManager.game_time
	var minutes: int = int(game_time / 60.0)
	var seconds: float = fmod(game_time, 60.0)

	# Check if we're at an odd minute (1, 3, 5, 7, etc.) and in first 30 seconds
	return minutes % 2 == 1 and seconds < 30.0

func _spawn_single_zombie() -> void:
	"""Spawn a single zombie enemy."""
	var spawn_pos := _get_random_spawn_position()
	var zombie: EnemyBase = _instantiate_enemy(_zombie_scene)

	if not zombie:
		return

	zombie.global_position = spawn_pos
	_apply_difficulty_scaling(zombie, false)

func _spawn_zombie_cat_pack() -> void:
	"""Spawn a pair of zombie cats side by side."""
	var current_enemies := get_tree().get_nodes_in_group("enemies")

	# Check if we have room for 2 enemies
	if current_enemies.size() + 2 > max_enemies:
		# Try to spawn at least one if there's room
		if current_enemies.size() >= max_enemies:
			return

	var center_pos := _get_random_spawn_position()
	var offset_distance: float = 30.0  # Distance between the two cats

	# Spawn first cat (slightly to the left)
	var cat1: EnemyBase = _instantiate_enemy(_zombie_cat_scene)
	if cat1:
		cat1.global_position = center_pos + Vector2(-offset_distance / 2, 0)
		_apply_difficulty_scaling(cat1, true)

	# Spawn second cat (slightly to the right) if there's room
	if current_enemies.size() + 1 < max_enemies:
		var cat2: EnemyBase = _instantiate_enemy(_zombie_cat_scene)
		if cat2:
			cat2.global_position = center_pos + Vector2(offset_distance / 2, 0)
			_apply_difficulty_scaling(cat2, true)

func _get_random_spawn_position() -> Vector2:
	"""Get a random spawn position around the player."""
	var angle := randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * spawn_distance
	return player.global_position + offset

func _instantiate_enemy(scene: PackedScene) -> EnemyBase:
	"""Instantiate an enemy from a scene."""
	if not scene:
		push_error("EnemySpawner: No scene provided for instantiation")
		return null

	var enemy: EnemyBase = scene.instantiate()
	get_parent().add_child(enemy)
	return enemy

func _apply_difficulty_scaling(enemy: EnemyBase, is_zombie_cat: bool = false) -> void:
	"""Apply time-based difficulty scaling to spawned enemy."""
	if not enemy.health_component:
		return

	# Get scaled health from GameManager based on elapsed time
	var scaled_health: int = GameManager.get_scaled_enemy_health()

	# Zombie cats have 50% of regular zombie health
	if is_zombie_cat:
		scaled_health = max(1, int(scaled_health * 0.5))

	# Set the enemy's max health and current health
	enemy.health_component.set_max_health(scaled_health)
	enemy.health_component.current_health = scaled_health
