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
var _big_zombie_scene: PackedScene
var _boss_scene: PackedScene
var _boss_spawned: bool = false
var _last_big_zombie_minute: int = -1  # Track last minute big zombie spawned

# Onready variables
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	_zombie_scene = load("res://scenes/enemies/zombie.tscn")
	_zombie_cat_scene = load("res://scenes/enemies/zombie_cat.tscn")
	_big_zombie_scene = load("res://scenes/enemies/big_zombie.tscn")
	_boss_scene = load("res://scenes/enemies/boss.tscn")

func _process(delta: float) -> void:
	# Check for big zombie spawn (every minute except minute 5)
	_check_big_zombie_spawn()

	# Check for boss spawn (at 5:00 exactly)
	_check_boss_spawn()

	# Regular enemy spawning (stop when boss is active)
	if not GameManager.is_boss_alive():
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

func _check_big_zombie_spawn() -> void:
	"""Check if it's time to spawn a big zombie (every minute except minute 5)."""
	var game_time: float = GameManager.game_time
	var minutes: int = int(game_time / 60.0)
	var seconds: float = fmod(game_time, 60.0)

	# Spawn big zombie at the start of each minute (first 2 seconds for safety)
	# Minutes 1, 2, 3, 4 (NOT 5 - that's for the boss)
	if seconds < 2.0 and minutes >= 1 and minutes < 5 and minutes != _last_big_zombie_minute:
		_last_big_zombie_minute = minutes
		_spawn_big_zombie()
		print("Big Zombie spawn triggered at %d:%02d" % [minutes, int(seconds)])

func _spawn_big_zombie() -> void:
	"""Spawn a single big zombie enemy."""
	var spawn_pos := _get_random_spawn_position()
	var big_zombie: EnemyBase = _instantiate_enemy(_big_zombie_scene)

	if not big_zombie:
		return

	big_zombie.global_position = spawn_pos
	_apply_big_zombie_scaling(big_zombie)
	print("Big Zombie spawned at minute %d" % int(GameManager.game_time / 60.0))

func _apply_big_zombie_scaling(enemy: EnemyBase) -> void:
	"""Apply 3x health multiplier to big zombie."""
	if not enemy.health_component:
		return

	# Get scaled health from GameManager and multiply by 3
	var scaled_health: int = GameManager.get_scaled_enemy_health()
	scaled_health = int(scaled_health * 3.0)  # 3x health multiplier

	enemy.health_component.set_max_health(scaled_health)
	enemy.health_component.current_health = scaled_health

func _check_boss_spawn() -> void:
	"""Check if it's time to spawn the boss (slightly before 5:00, once per stage)."""
	var game_time: float = GameManager.game_time

	# Spawn boss slightly before 5:00 (at 299.5 seconds) to ensure it's alive before stage completion check
	if game_time >= 299.5 and not _boss_spawned:
		_boss_spawned = true
		_spawn_boss()

func _spawn_boss() -> void:
	"""Spawn the boss enemy."""
	var spawn_pos := _get_random_spawn_position()
	var boss: EnemyBase = _instantiate_enemy(_boss_scene)

	if not boss:
		return

	boss.global_position = spawn_pos
	_apply_boss_scaling(boss)
	print("BOSS SPAWNED at 5:00!")

func _apply_boss_scaling(enemy: EnemyBase) -> void:
	"""Apply 10x health multiplier to boss."""
	if not enemy.health_component:
		return

	# Get scaled health from GameManager and multiply by 10
	var scaled_health: int = GameManager.get_scaled_enemy_health()
	scaled_health = int(scaled_health * 10.0)  # 10x health multiplier

	enemy.health_component.set_max_health(scaled_health)
	enemy.health_component.current_health = scaled_health

func reset_for_new_stage() -> void:
	"""Reset spawner state for a new stage."""
	_boss_spawned = false
	_last_big_zombie_minute = -1
