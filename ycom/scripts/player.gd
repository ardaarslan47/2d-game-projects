class_name Player
extends CharacterBody2D

## Player character controller for XCOM-like turn-based movement.
## Handles smooth tile-to-tile movement on a 64x64 grid.

# Exported variables
@export var movement_speed: float = 300.0

# Private variables
var _is_moving: bool = false
var _target_position: Vector2 = Vector2.ZERO
var _current_direction: String = "south"  # Default facing direction

# Onready variables
@onready var walk_animation: AnimatedSprite2D = $walk_animation


func _ready() -> void:
	# Snap player to grid on start
	global_position = _snap_to_grid(global_position)
	print("Player: Ready at position ", global_position)


func _physics_process(delta: float) -> void:
	if _is_moving:
		_process_movement(delta)


## Move player to the specified tile coordinates.
## tile_pos: Vector2i representing the grid coordinates (e.g., Vector2i(5, 3))
func move_to_tile(tile_pos: Vector2i) -> void:
	if _is_moving:
		return  # Don't interrupt current movement

	_target_position = _tile_to_world(tile_pos)

	print("Player: Moving from ", global_position, " to ", _target_position)

	# Calculate direction and play appropriate walk animation
	_current_direction = _calculate_direction(global_position, _target_position)
	print("Player: Playing animation: ", _current_direction)
	walk_animation.play(_current_direction)

	_is_moving = true


## Check if the player is currently moving.
func is_moving() -> bool:
	return _is_moving


## Get current tile position of the player.
func get_current_tile() -> Vector2i:
	return _world_to_tile(global_position)


# Private methods
## Calculate the direction name based on movement vector for 8-directional animations.
## Returns one of: "east", "south-east", "south", "south-west", "west", "north-west", "north", "north-east"
func _calculate_direction(from: Vector2, to: Vector2) -> String:
	var direction_vector: Vector2 = (to - from).normalized()
	var angle: float = direction_vector.angle()

	# Convert angle to degrees for easier calculation
	var degrees: float = rad_to_deg(angle)

	# Normalize to 0-360 range
	if degrees < 0:
		degrees += 360

	# Map angle to 8 directions (45-degree segments)
	# Each direction covers 45 degrees, centered on its cardinal/ordinal direction
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


func _process_movement(delta: float) -> void:
	var direction: Vector2 = global_position.direction_to(_target_position)
	var distance: float = global_position.distance_to(_target_position)

	# Check if we've reached the target
	if distance < movement_speed * delta:
		global_position = _target_position
		_is_moving = false
		# Stop animation when movement completes
		walk_animation.stop()
		return

	# Move toward target
	velocity = direction * movement_speed
	move_and_slide()


func _snap_to_grid(pos: Vector2) -> Vector2:
	var tile: Vector2i = _world_to_tile(pos)
	return _tile_to_world(tile)


func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / Constants.TILE_SIZE)),
		int(floor(world_pos.y / Constants.TILE_SIZE))
	)


func _tile_to_world(tile_pos: Vector2i) -> Vector2:
	# Center the position in the tile
	return Vector2(
		tile_pos.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		tile_pos.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
	)
