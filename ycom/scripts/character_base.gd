class_name CharacterBase
extends CharacterBody2D

## Base class for all turn-based characters (Player, Enemy).
## Contains shared functionality: movement, action points, health, combat.
## Eliminates code duplication between Player and Enemy classes.

# Signals
signal action_points_changed(current_ap: int, max_ap: int)
signal action_points_depleted
signal movement_completed
signal health_changed(current_health: int, max_health: int)
signal died

# Exported variables
@export var movement_speed: float = 300.0
@export var max_action_points: int = 2
@export var max_health: int = 20
@export var base_attack_damage: int = 5

# Health
var current_health: int = 20

# Action Points
var current_action_points: int = 2

# Protected variables (subclasses can access)
var _is_moving: bool = false
var _target_position: Vector2 = Vector2.ZERO
var _current_direction: String = "south"
var _movement_path: Array[Vector2i] = []
var _current_path_index: int = 0
var _movement_stuck_timer: float = 0.0
const MAX_MOVEMENT_TIME_PER_TILE: float = 5.0

# Cached grid system reference
var _grid_system: GridSystem = null

# Character type for tile registration
var _character_tile_state: int = 0  # Set by subclasses (Player or Enemy)


func _ready() -> void:
	# Snap to grid on start
	global_position = _snap_to_grid(global_position)

	# Initialize stats
	current_action_points = max_action_points
	current_health = max_health

	# Cache grid system reference
	_grid_system = get_tree().get_first_node_in_group("grid")
	if _grid_system == null:
		push_warning("CharacterBase: Cannot find grid system!")

	_on_character_ready()

	# Register initial tile position
	if _grid_system and _character_tile_state != 0:
		_register_tile_position(get_current_tile())


## Override this in subclasses for character-specific initialization.
func _on_character_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if _is_moving:
		_process_movement(delta)


## Move character to the specified tile using pathfinding.
func move_to_tile(tile_pos: Vector2i) -> void:
	if _is_moving:
		return  # Don't interrupt current movement

	if _grid_system == null:
		push_error("CharacterBase: No grid system available!")
		return

	# Find path to destination
	var current_tile: Vector2i = get_current_tile()
	_movement_path = _grid_system.find_path(current_tile, tile_pos)

	if _movement_path.is_empty():
		return

	# Remove starting position from path
	if _movement_path.size() > 0 and _movement_path[0] == current_tile:
		_movement_path.remove_at(0)

	if _movement_path.is_empty():
		return

	# Start moving along the path
	_current_path_index = 0
	_movement_stuck_timer = 0.0
	_move_to_next_tile_in_path()


## Check if character is currently moving.
func is_moving() -> bool:
	return _is_moving


## Get current tile position.
func get_current_tile() -> Vector2i:
	if _grid_system:
		return _grid_system.world_to_tile(global_position)
	# Fallback if grid system not available
	return Vector2i(
		int(round(global_position.x / Constants.TILE_SIZE)),
		int(round(global_position.y / Constants.TILE_SIZE))
	)


## Check if character can afford an action.
func can_afford_action(cost: int) -> bool:
	return current_action_points >= cost


## Spend action points. Returns true if successful.
func spend_action_points(cost: int) -> bool:
	if not can_afford_action(cost):
		return false

	current_action_points -= cost
	action_points_changed.emit(current_action_points, max_action_points)

	if current_action_points == 0:
		action_points_depleted.emit()

	return true


## Reset action points to max (called at start of turn).
func reset_action_points() -> void:
	current_action_points = max_action_points
	action_points_changed.emit(current_action_points, max_action_points)


## Get the AP cost for moving between tiles.
func get_movement_cost(_from_tile: Vector2i, _to_tile: Vector2i) -> int:
	return 1  # Override in subclass if needed


## Get current action points.
func get_action_points() -> int:
	return current_action_points


## Get maximum action points.
func get_max_action_points() -> int:
	return max_action_points


## Attack a target character.
func attack_target(target: CharacterBase) -> bool:
	if target == null or not is_instance_valid(target):
		return false

	# Calculate distance
	var attacker_tile: Vector2i = get_current_tile()
	var target_tile: Vector2i = target.get_current_tile()
	var distance: float = float(abs(target_tile.x - attacker_tile.x) + abs(target_tile.y - attacker_tile.y))

	if distance > Constants.ATTACK_RANGE:
		return false

	# Deal damage
	target.take_damage(base_attack_damage)
	return true


## Take damage from an attack.
func take_damage(amount: int) -> void:
	# Check if already dead
	if current_health <= 0:
		return

	current_health -= amount
	health_changed.emit(current_health, max_health)

	# Visual feedback (override in subclass)
	_on_take_damage_feedback(amount)

	if current_health <= 0:
		current_health = 0
		die()


## Override this for character-specific damage feedback (flash, popup, etc).
func _on_take_damage_feedback(_amount: int) -> void:
	pass


## Handle character death.
func die() -> void:
	died.emit()
	_on_death()


## Override this for character-specific death behavior.
func _on_death() -> void:
	# Unregister from grid when dying
	if _grid_system and _character_tile_state != 0:
		_unregister_tile_position(get_current_tile())


# ========================================
# Tile Registration (Grid Integration)
# ========================================

## Register this character's position in the grid.
func _register_tile_position(tile_pos: Vector2i) -> void:
	if _grid_system == null or _character_tile_state == 0:
		return

	_grid_system.add_tile_state(tile_pos, _character_tile_state)


## Unregister this character's position from the grid.
func _unregister_tile_position(tile_pos: Vector2i) -> void:
	if _grid_system == null or _character_tile_state == 0:
		return

	_grid_system.remove_tile_state(tile_pos, _character_tile_state)


# Private movement methods

## Move to next tile in the current path.
func _move_to_next_tile_in_path() -> void:
	if _current_path_index >= _movement_path.size():
		_complete_movement()
		return

	var next_tile: Vector2i = _movement_path[_current_path_index]
	_target_position = _tile_to_world(next_tile)
	_is_moving = true
	_movement_stuck_timer = 0.0

	# Update facing direction
	_current_direction = _calculate_direction(global_position, _target_position)
	_update_animation()


## Process movement each frame.
func _process_movement(delta: float) -> void:
	# Safety check - detect stuck movement
	_movement_stuck_timer += delta
	if _movement_stuck_timer > MAX_MOVEMENT_TIME_PER_TILE:
		push_warning("CharacterBase: Movement stuck, forcing completion")
		_complete_current_tile_movement()
		return

	var distance_to_target: float = global_position.distance_to(_target_position)

	# Check if reached target
	if distance_to_target < 2.0:
		_complete_current_tile_movement()
		return

	# Move toward target with grid-aligned movement
	var direction_to_target: Vector2 = _target_position - global_position

	# Prioritize axis-aligned movement (move horizontally OR vertically, not both)
	if abs(direction_to_target.x) > abs(direction_to_target.y):
		# Move horizontally only
		direction_to_target.y = 0
	else:
		# Move vertically only
		direction_to_target.x = 0

	direction_to_target = direction_to_target.normalized()
	velocity = direction_to_target * movement_speed
	move_and_slide()


## Complete movement to current tile and move to next.
func _complete_current_tile_movement() -> void:
	# Unregister old tile position
	var old_tile: Vector2i = get_current_tile()

	# Snap to exact target position
	global_position = _target_position

	# Register new tile position
	var new_tile: Vector2i = get_current_tile()
	if old_tile != new_tile:
		_unregister_tile_position(old_tile)
		_register_tile_position(new_tile)

	_current_path_index += 1

	# Check if more tiles to move to
	if _current_path_index < _movement_path.size():
		_move_to_next_tile_in_path()
	else:
		_complete_movement()


## Complete all movement.
func _complete_movement() -> void:
	_is_moving = false
	_movement_path.clear()
	_current_path_index = 0
	velocity = Vector2.ZERO
	_stop_animation()
	movement_completed.emit()


## Calculate direction for animation based on movement vector.
## Override in subclass if you have fewer than 8 directions.
func _calculate_direction(from: Vector2, to: Vector2) -> String:
	var direction_vector: Vector2 = (to - from).normalized()
	var angle: float = direction_vector.angle()
	var degrees: float = rad_to_deg(angle)

	# Normalize to 0-360
	if degrees < 0:
		degrees += 360

	# Map to 8 directions
	if degrees >= 337.5 or degrees < 22.5:
		return "east"
	elif degrees >= 22.5 and degrees < 67.5:
		return "south-east"
	elif degrees >= 67.5 and degrees < 112.5:
		return "south"
	elif degrees >= 112.5 and degrees < 157.5:
		return "south-west"
	elif degrees >= 157.5 and degrees < 202.5:
		return "west"
	elif degrees >= 202.5 and degrees < 247.5:
		return "north-west"
	elif degrees >= 247.5 and degrees < 292.5:
		return "north"
	else:  # 292.5 to 337.5
		return "north-east"


## Snap position to grid alignment.
func _snap_to_grid(pos: Vector2) -> Vector2:
	if _grid_system:
		var tile: Vector2i = _grid_system.world_to_tile(pos)
		return _grid_system.tile_to_world(tile)
	# Fallback
	return Vector2(
		round(pos.x / Constants.TILE_SIZE) * Constants.TILE_SIZE,
		round(pos.y / Constants.TILE_SIZE) * Constants.TILE_SIZE
	)


## Convert tile coordinates to world position.
func _tile_to_world(tile: Vector2i) -> Vector2:
	if _grid_system:
		return _grid_system.tile_to_world(tile)
	# Fallback
	return Vector2(tile.x * Constants.TILE_SIZE, tile.y * Constants.TILE_SIZE)


## Update animation based on current direction and movement state.
## Override in subclass to implement actual animation logic.
func _update_animation() -> void:
	pass


## Stop animation.
## Override in subclass to implement actual animation logic.
func _stop_animation() -> void:
	pass
