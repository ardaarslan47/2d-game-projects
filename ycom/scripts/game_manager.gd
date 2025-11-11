class_name GameManager
extends Node2D

## Game manager for XCOM-like turn-based gameplay.
## Handles mouse input, coordinates player movement, attack targeting, and enforces turn-based rules.
## Works with chunk-based infinite grid system and GridVisualizer for range display.

# Node references
@onready var player: Player = $player
@onready var grid_system: GridSystem = $GridSystem
@onready var turn_manager: Node = $TurnManager
@onready var ui_manager: CanvasLayer = $UIManager
@onready var grid_visualizer: Node2D = $GridVisualizer

# State
var is_selecting_action: bool = false  # True when action button is pressed


func _ready() -> void:
	# Validate node references
	if player == null:
		push_error("GameManager: Player reference not set!")
		return

	print("GameManager: Player reference set correctly: ", player)

	# Connect to player signals
	player.movement_completed.connect(_on_player_movement_completed)

	if grid_system == null:
		push_error("GameManager: GridSystem reference not set!")
		return

	if turn_manager == null:
		push_error("GameManager: TurnManager reference not set!")
		return

	if grid_visualizer == null:
		push_warning("GameManager: GridVisualizer not found - no range visualization")

	if ui_manager == null:
		push_warning("GameManager: UIManager not found - no UI")

	print("GameManager: Initialized for chunk-based grid system")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_click(event)


func _handle_mouse_click(event: InputEventMouseButton) -> void:
	# Handle left click
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_left_click()
		return



func _handle_left_click() -> void:
	if player == null or grid_system == null:
		return

	# Check if it's the player's turn
	if not GameState.can_player_act():
		print("GameManager: Not player's turn! Current state: ", GameState.get_state_name())
		return

	# Don't allow new commands while player is moving
	if player.is_moving():
		print("GameManager: Player is already moving, ignoring click")
		return

	# Check if GridVisualizer has a mode selected
	if grid_visualizer == null:
		print("GameManager: No GridVisualizer - cannot determine action mode")
		return

	var visualizer_mode: int = grid_visualizer.get_mode()

	# Handle based on GridVisualizer's current mode
	if visualizer_mode == grid_visualizer.PlayerMode.MOVE:
		_handle_move_tile_click()
	elif visualizer_mode == grid_visualizer.PlayerMode.ATTACK:
		_handle_attack_tile_click()

	# Mark input as handled
	get_viewport().set_input_as_handled()


## Handle clicking a tile in MOVE_MODE.
func _handle_move_tile_click() -> void:
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	var target_tile: Vector2i = grid_system.world_to_tile(mouse_world_pos)

	# Validate tile is walkable
	if not grid_system.is_tile_walkable(target_tile):
		print("GameManager: Clicked tile is not walkable")
		return

	# Get path from player to target
	var current_tile: Vector2i = player.get_current_tile()
	var path: Array[Vector2i] = grid_system.find_path(current_tile, target_tile)

	if path.is_empty():
		print("GameManager: No path to target tile!")
		return

	# Remove starting position from path
	if path.size() > 0 and path[0] == current_tile:
		path.remove_at(0)

	var movement_cost: int = path.size()

	# Check if player can afford the movement
	if not player.can_afford_action(movement_cost):
		print("GameManager: Cannot afford movement (needs ", movement_cost, " AP, have ", player.get_action_points(), ")!")
		return

	print("GameManager: Moving player to tile ", target_tile, " via ", movement_cost, "-step path")

	# Spend action points
	if not player.spend_action_points(movement_cost):
		print("GameManager: Failed to spend action points!")
		return

	# Change state to animating
	GameState.change_state(GameState.GameStates.ANIMATING)

	# Command player to move
	player.move_to_tile(target_tile)


## Handle clicking a tile in ATTACK_MODE.
func _handle_attack_tile_click() -> void:
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	var target_tile: Vector2i = grid_system.world_to_tile(mouse_world_pos)

	# Check if there's an enemy at this tile
	var clicked_enemy: Enemy = _get_enemy_at_tile(target_tile)
	if clicked_enemy == null:
		print("GameManager: No enemy at clicked tile")
		return

	# Check if enemy is in attack range
	if not _is_in_attack_range(clicked_enemy):
		print("GameManager: Enemy not in attack range")
		return

	# Check if player can afford attack
	if not player.can_afford_action(Constants.ATTACK_COST):
		print("GameManager: Cannot afford attack (needs ", Constants.ATTACK_COST, " AP, have ", player.get_action_points(), ")!")
		return

	print("GameManager: Player attacking enemy at ", target_tile)

	# Spend AP
	if not player.spend_action_points(Constants.ATTACK_COST):
		print("GameManager: Failed to spend action points!")
		return

	# Perform attack
	player.attack_enemy(clicked_enemy)


## Get the tile coordinates under the mouse cursor.
func get_mouse_tile_position() -> Vector2i:
	var mouse_world_pos: Vector2 = get_global_mouse_position()
	return grid_system.world_to_tile(mouse_world_pos)


# Private methods


## Check if an enemy is within attack range of the player.
func _is_in_attack_range(enemy: Enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false

	var player_tile: Vector2i = player.get_current_tile()
	var enemy_tile: Vector2i = enemy.get_current_tile()

	# Manhattan distance
	var distance: int = abs(enemy_tile.x - player_tile.x) + abs(enemy_tile.y - player_tile.y)
	return distance <= Constants.ATTACK_RANGE


## Get the enemy at a specific tile position.
func _get_enemy_at_tile(tile: Vector2i) -> Enemy:
	var all_enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for node in all_enemies:
		if node is Enemy:
			var enemy: Enemy = node as Enemy
			if enemy.get_current_tile() == tile:
				return enemy
	return null




# Signal handlers
func _on_player_movement_completed() -> void:
	print("GameManager: Player movement completed")
	# Return to player turn state (animation finished)
	GameState.finish_animation()
