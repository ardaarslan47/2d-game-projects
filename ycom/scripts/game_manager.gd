class_name GameManager
extends Node2D

## Game manager for XCOM-like turn-based gameplay.
## Handles mouse input and coordinates player movement.

# Exported variables
@onready var player: CharacterBody2D = $player

# Private variables
var _mouse_tile_pos: Vector2i = Vector2i.ZERO


func _ready() -> void:
	if player == null:
		push_warning("GameManager: Player reference not set! Assign player in the inspector.")
	else:
		print("GameManager: Player reference set correctly: ", player)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_click(event)


func _handle_mouse_click(event: InputEventMouseButton) -> void:
	# Only respond to left click press
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	print("GameManager: Mouse clicked!")

	if player == null:
		print("GameManager: Player is null!")
		return

	# Don't allow new commands while player is moving
	if player.is_moving():
		print("GameManager: Player is already moving, ignoring click")
		return

	# Convert mouse position to tile coordinates
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	var target_tile: Vector2i = _world_to_tile(mouse_world_pos)

	print("GameManager: Moving player to tile: ", target_tile)

	# Command player to move to clicked tile
	player.move_to_tile(target_tile)

	# Mark input as handled
	get_viewport().set_input_as_handled()


## Get the tile coordinates under the mouse cursor.
func get_mouse_tile_position() -> Vector2i:
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	return _world_to_tile(mouse_world_pos)


# Private methods
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
