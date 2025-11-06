class_name ProjectilePool
extends Node

## Object pool for projectiles to improve performance.
## Pre-allocates projectiles and reuses them instead of constantly creating/destroying.

# Exported variables
@export var projectile_scene: PackedScene
@export var initial_pool_size: int = 20  # Pre-allocate this many projectiles
@export var max_pool_size: int = 50  # Don't keep more than this in reserve

# Private variables
var _pool: Array[Projectile] = []
var _active_projectiles: Array[Projectile] = []

func _ready() -> void:
	assert(projectile_scene != null, "ProjectilePool: projectile_scene must be set")
	# Defer prewarm to avoid "parent busy" error during scene setup
	_prewarm_pool.call_deferred()

# Public methods
func get_projectile() -> Projectile:
	"""Get a projectile from the pool, creating a new one if pool is empty."""
	var projectile: Projectile

	if _pool.is_empty():
		projectile = _create_projectile()
	else:
		projectile = _pool.pop_back()

	# Reset and activate projectile
	_activate_projectile(projectile)
	_active_projectiles.append(projectile)

	return projectile

func return_projectile(projectile: Projectile) -> void:
	"""Return a projectile to the pool for reuse."""
	if projectile == null:
		return

	# Remove from active list
	var index: int = _active_projectiles.find(projectile)
	if index >= 0:
		_active_projectiles.remove_at(index)

	# Don't keep more than max_pool_size in reserve
	if _pool.size() < max_pool_size:
		_deactivate_projectile(projectile)
		_pool.append(projectile)
	else:
		# Pool is full, actually free the projectile
		projectile.queue_free()

func get_pool_size() -> int:
	"""Get the current number of projectiles in reserve."""
	return _pool.size()

func get_active_count() -> int:
	"""Get the number of projectiles currently in use."""
	return _active_projectiles.size()

func clear_active_projectiles() -> void:
	"""Return all active projectiles to the pool (useful for scene transitions)."""
	for projectile in _active_projectiles.duplicate():
		return_projectile(projectile)

# Private methods
func _prewarm_pool() -> void:
	"""Pre-create projectiles to avoid runtime allocation spikes."""
	for i in range(initial_pool_size):
		var projectile: Projectile = _create_projectile()
		_deactivate_projectile(projectile)
		_pool.append(projectile)

func _create_projectile() -> Projectile:
	"""Create a new projectile instance."""
	var projectile: Projectile = projectile_scene.instantiate()

	# Add to tree but keep inactive
	get_tree().current_scene.add_child(projectile)

	# Set reference to this pool so projectile can return itself
	projectile.set_pool(self)

	return projectile

func _activate_projectile(projectile: Projectile) -> void:
	"""Activate a projectile from the pool."""
	# Reset state FIRST before enabling anything
	projectile.reset_state()

	# If projectile was removed from tree, re-add it
	if not projectile.is_inside_tree():
		get_tree().current_scene.add_child(projectile)

	# Enable processing AFTER reset
	projectile.set_process(true)
	projectile.set_physics_process(true)
	projectile.show()

func _deactivate_projectile(projectile: Projectile) -> void:
	"""Deactivate a projectile and return it to pool."""
	projectile.set_process(false)
	projectile.set_physics_process(false)
	projectile.hide()

	# Disable Area2D collision detection
	projectile.set_deferred("monitoring", false)
	projectile.set_deferred("monitorable", false)

	# Stop the lifetime timer to prevent timeout while pooled
	if projectile.lifetime_timer and not projectile.lifetime_timer.is_stopped():
		projectile.lifetime_timer.stop()

	# Move off-screen to ensure no interactions
	projectile.global_position = Vector2(-10000, -10000)
