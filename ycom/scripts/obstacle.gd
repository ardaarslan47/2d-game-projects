class_name Obstacle
extends StaticBody2D

## Base class for map obstacles that block movement and provide cover.

@export var blocks_movement: bool = true
@export var provides_cover: bool = true
@export var cover_bonus: int = 20  # Defense bonus percentage
@export var destructible: bool = false
@export var max_health: int = 50

var current_health: int = max_health

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("obstacles")
	current_health = max_health

	# Set collision layer/mask for obstacles
	collision_layer = 4  # Layer 3 for obstacles
	collision_mask = 0   # Obstacles don't need to detect anything

	# Register obstacle position in grid
	if blocks_movement:
		_register_in_grid()

func take_damage(amount: int) -> void:
	if not destructible:
		return

	current_health -= amount
	if current_health <= 0:
		_destroy()

func _destroy() -> void:
	# Unregister from grid before destruction
	_unregister_from_grid()

	# TODO: Add destruction animation/effects
	queue_free()

## Check if this obstacle provides cover for a unit at given position
func provides_cover_for(_unit_position: Vector2) -> bool:
	if not provides_cover:
		return false

	# Check if obstacle is between unit and potential attacker
	# This is a simplified check - actual cover calculation would be more complex
	return true


# ========================================
# Grid Integration
# ========================================

## Register this obstacle in the grid system.
func _register_in_grid() -> void:
	var grid: GridSystem = get_tree().get_first_node_in_group("grid") as GridSystem
	if grid == null:
		push_warning("Obstacle: Cannot find grid system for registration")
		return

	var tile_pos: Vector2i = grid.world_to_tile(global_position)
	grid.add_tile_state(tile_pos, GridSystem.TileState.OBSTACLE)


## Unregister this obstacle from the grid system.
func _unregister_from_grid() -> void:
	var grid: GridSystem = get_tree().get_first_node_in_group("grid") as GridSystem
	if grid == null:
		return

	var tile_pos: Vector2i = grid.world_to_tile(global_position)
	grid.remove_tile_state(tile_pos, GridSystem.TileState.OBSTACLE)
