class_name Player
extends CharacterBase

## Player character controller for XCOM-like turn-based movement.
## Handles smooth tile-to-tile movement on a 64x64 grid with action point system.

# Onready variables
@onready var walk_animation: AnimatedSprite2D = $walk_animation


## Character-specific initialization (called by base class).
func _on_character_ready() -> void:
	# Set tile state type for grid registration
	_character_tile_state = GridSystem.TileState.PLAYER
	print("Player: Ready at position ", global_position, " with ", current_action_points, " AP and ", current_health, " HP")


## Override base class to add logging.
func move_to_tile(tile_pos: Vector2i) -> void:
	if _is_moving:
		return

	if _grid_system == null:
		push_error("Player: Cannot find grid system for pathfinding!")
		return

	var current_tile: Vector2i = get_current_tile()
	_movement_path = _grid_system.find_path(current_tile, tile_pos)

	if _movement_path.is_empty():
		print("Player: No path found to ", tile_pos)
		return

	# Remove starting position
	if _movement_path.size() > 0 and _movement_path[0] == current_tile:
		_movement_path.remove_at(0)

	if _movement_path.is_empty():
		print("Player: Already at destination")
		return

	print("Player: Moving along path with ", _movement_path.size(), " steps")

	_current_path_index = 0
	_movement_stuck_timer = 0.0
	_move_to_next_tile_in_path()


## Override to add logging.
func spend_action_points(cost: int) -> bool:
	if not can_afford_action(cost):
		print("Player: Cannot afford action (cost: ", cost, ", current AP: ", current_action_points, ")")
		return false

	current_action_points -= cost
	print("Player: Spent ", cost, " AP. Remaining: ", current_action_points)
	action_points_changed.emit(current_action_points, max_action_points)

	if current_action_points == 0:
		action_points_depleted.emit()

	return true


## Override to add logging.
func reset_action_points() -> void:
	current_action_points = max_action_points
	print("Player: Action points reset to ", current_action_points)
	action_points_changed.emit(current_action_points, max_action_points)


## Attack a target enemy (wrapper for type safety).
func attack_enemy(target: Enemy) -> bool:
	if target == null or not is_instance_valid(target):
		print("Player: Invalid attack target")
		return false

	print("Player: Attacking enemy at ", target.get_current_tile(), " for ", base_attack_damage, " damage")
	return attack_target(target)


## Override to add logging.
func take_damage(amount: int) -> void:
	if current_health <= 0:
		return

	current_health -= amount
	print("Player: Took ", amount, " damage. HP: ", current_health, "/", max_health)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		current_health = 0
		die()


## Override death handler.
func _on_death() -> void:
	print("Player: Died")
	# Note: Don't queue_free() - let GameManager handle game over state


## Update animation based on movement direction.
func _update_animation() -> void:
	if walk_animation:
		walk_animation.play(_current_direction)


## Stop animation when movement completes.
func _stop_animation() -> void:
	if walk_animation:
		walk_animation.stop()


## Override to log completion.
func _complete_movement() -> void:
	super._complete_movement()
	print("Player: Movement completed at tile ", get_current_tile())
