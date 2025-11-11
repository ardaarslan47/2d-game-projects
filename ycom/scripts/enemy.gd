class_name Enemy
extends CharacterBase

## Basic enemy character for XCOM-like turn-based gameplay.
## Similar to Player but controlled by AI.

# Onready variables
@onready var walk_animation: AnimatedSprite2D = $walk_animation


## Character-specific initialization (called by base class).
func _on_character_ready() -> void:
	# Set tile state type for grid registration
	_character_tile_state = GridSystem.TileState.ENEMY

	# Set default enemy stats
	movement_speed = 200.0
	print("Enemy: Ready at position ", global_position, " with ", current_action_points, " AP and ", current_health, " HP")


## Override move_to_tile to use single-tile movement (no multi-tile pathfinding).
## Enemy AI moves one tile at a time toward player.
func move_to_tile(tile_pos: Vector2i) -> void:
	if _is_moving:
		return

	if _grid_system == null:
		push_error("Enemy: Cannot find grid system!")
		return

	var current_tile: Vector2i = get_current_tile()

	# Validate target tile is walkable
	if not _grid_system.is_tile_walkable(tile_pos):
		print("Enemy: Target tile ", tile_pos, " is not walkable")
		return

	# Enemy moves directly to single tile (no pathfinding path)
	# AI handles pathfinding, this just moves to the given tile
	_movement_path = [tile_pos]
	_current_path_index = 0
	_movement_stuck_timer = 0.0

	print("Enemy: Moving from ", current_tile, " to ", tile_pos)

	_move_to_next_tile_in_path()


## Override to add logging.
func spend_action_points(cost: int) -> bool:
	if not can_afford_action(cost):
		print("Enemy: Cannot afford action (cost: ", cost, ", current AP: ", current_action_points, ")")
		return false

	current_action_points -= cost
	print("Enemy: Spent ", cost, " AP. Remaining: ", current_action_points)
	action_points_changed.emit(current_action_points, max_action_points)

	if current_action_points == 0:
		action_points_depleted.emit()

	return true


## Override to add logging.
func reset_action_points() -> void:
	current_action_points = max_action_points
	print("Enemy: Action points reset to ", current_action_points)
	action_points_changed.emit(current_action_points, max_action_points)


## Attack the player (wrapper for type safety).
func attack_player(target: Player) -> bool:
	if target == null or not is_instance_valid(target):
		print("Enemy: Invalid attack target")
		return false

	print("Enemy: Attacking player at ", target.get_current_tile(), " for ", base_attack_damage, " damage")
	return attack_target(target)


## Override damage feedback to show red flash and popup.
func _on_take_damage_feedback(amount: int) -> void:
	print("Enemy: Took ", amount, " damage. Health: ", current_health, "/", max_health)
	_flash_red()
	_spawn_damage_popup(amount)


## Flash red to indicate taking damage.
func _flash_red() -> void:
	if walk_animation:
		walk_animation.modulate = Color(1.5, 0.3, 0.3)  # Red tint
		var tween: Tween = create_tween()
		tween.tween_property(walk_animation, "modulate", Color(1.0, 1.0, 1.0), 0.2)


## Spawn a damage number popup.
func _spawn_damage_popup(damage: int) -> void:
	var damage_popup_scene: PackedScene = load("res://scenes/ui/damage_popup.tscn")
	if damage_popup_scene:
		var popup: Node2D = damage_popup_scene.instantiate()
		popup.damage_amount = damage
		popup.global_position = global_position + Vector2(0, -20)
		get_tree().root.add_child(popup)


## Override death handler.
func _on_death() -> void:
	# Call parent to unregister from grid
	super._on_death()

	print("Enemy: Died at ", get_current_tile())

	# Remove from enemies group (this will auto-unregister from TurnManager)
	remove_from_group("enemies")

	# Queue for deletion with slight delay for death animation if needed
	queue_free()


## Override direction calculation to handle 4-direction animations.
## Enemy only has: south, west, south-west, north-west
func _calculate_direction(from: Vector2, to: Vector2) -> String:
	var direction_vector: Vector2 = (to - from).normalized()
	var angle: float = direction_vector.angle()
	var degrees: float = rad_to_deg(angle)

	# Normalize to 0-360 range
	if degrees < 0:
		degrees += 360

	# Map angle to available 4 directions
	if degrees >= 337.5 or degrees < 22.5:
		return "south"  # East fallback
	elif degrees >= 22.5 and degrees < 67.5:
		return "south"  # South-east fallback
	elif degrees >= 67.5 and degrees < 112.5:
		return "south"
	elif degrees >= 112.5 and degrees < 157.5:
		return "south-west"
	elif degrees >= 157.5 and degrees < 202.5:
		return "west"
	elif degrees >= 202.5 and degrees < 247.5:
		return "north-west"
	elif degrees >= 247.5 and degrees < 292.5:
		return "north-west"  # North fallback
	else:  # 292.5 to 337.5
		return "north-west"  # North-east fallback


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
	print("Enemy: Movement completed at tile ", get_current_tile())
