class_name EnemyPool
extends Node

## Object pool for enemies to improve performance.
## Pre-allocates enemies and reuses them instead of constantly creating/destroying.

# Exported variables
@export var enemy_scene: PackedScene
@export var initial_pool_size: int = 20  # Pre-allocate this many enemies
@export var max_pool_size: int = 50  # Don't keep more than this in reserve

# Private variables
var _pool: Array[EnemyBase] = []
var _active_enemies: Array[EnemyBase] = []

func _ready() -> void:
	assert(enemy_scene != null, "EnemyPool: enemy_scene must be set")
	# Defer prewarm to avoid "parent busy" error during scene setup
	_prewarm_pool.call_deferred()

# Public methods
func get_enemy() -> EnemyBase:
	"""Get an enemy from the pool, creating a new one if pool is empty."""
	var enemy: EnemyBase

	if _pool.is_empty():
		enemy = _create_enemy()
	else:
		enemy = _pool.pop_back()

	# Reset and activate enemy
	_activate_enemy(enemy)
	_active_enemies.append(enemy)

	return enemy

func return_enemy(enemy: EnemyBase) -> void:
	"""Return an enemy to the pool for reuse."""
	if enemy == null:
		return

	# Remove from active list
	var index: int = _active_enemies.find(enemy)
	if index >= 0:
		_active_enemies.remove_at(index)

	# Don't keep more than max_pool_size in reserve
	if _pool.size() < max_pool_size:
		_deactivate_enemy(enemy)
		_pool.append(enemy)
	else:
		# Pool is full, actually free the enemy
		enemy.queue_free()

func get_pool_size() -> int:
	"""Get the current number of enemies in reserve."""
	return _pool.size()

func get_active_count() -> int:
	"""Get the number of enemies currently in use."""
	return _active_enemies.size()

func clear_active_enemies() -> void:
	"""Return all active enemies to the pool (useful for scene transitions)."""
	for enemy in _active_enemies.duplicate():
		return_enemy(enemy)

# Private methods
func _prewarm_pool() -> void:
	"""Pre-create enemies to avoid runtime allocation spikes."""
	for i in range(initial_pool_size):
		var enemy: EnemyBase = _create_enemy()
		_deactivate_enemy(enemy)
		_pool.append(enemy)

func _create_enemy() -> EnemyBase:
	"""Create a new enemy instance."""
	var enemy: EnemyBase = enemy_scene.instantiate()

	# Add to tree but keep inactive
	get_tree().current_scene.add_child(enemy)

	# Set reference to this pool so enemy can return itself
	enemy.set_pool(self)

	return enemy

func _activate_enemy(enemy: EnemyBase) -> void:
	"""Activate an enemy from the pool."""
	# If enemy was removed from tree, re-add it FIRST
	if not enemy.is_inside_tree():
		get_tree().current_scene.add_child(enemy)

	# Now reset state (enemy is in tree so get_tree() works)
	enemy.reset_state()

	# Enable processing AFTER reset
	enemy.set_process(true)
	enemy.set_physics_process(true)
	enemy.show()

func _deactivate_enemy(enemy: EnemyBase) -> void:
	"""Deactivate an enemy and return it to pool."""
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.hide()

	# Disable collision to avoid physics interactions
	if enemy.collision:
		enemy.collision.set_deferred("disabled", true)

	# Disable hitbox collision as well
	if enemy.hitbox:
		enemy.hitbox.set_deferred("monitoring", false)
		enemy.hitbox.set_deferred("monitorable", false)

	# Move off-screen to ensure no interactions (after disabling collision)
	enemy.global_position = Vector2(-10000, -10000)
