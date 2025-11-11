extends Node

## Simple enemy AI for turn-based gameplay with chunk-based infinite grid.
## Moves enemy toward the player each turn using pathfinding.

# Node references (initialized in _ready)
var enemy: Enemy = null
var player: Player = null
var grid_system: GridSystem = null


func _ready() -> void:
	# Get reference to the enemy (parent)
	enemy = get_parent() as Enemy
	if enemy == null:
		push_error("EnemyAI: Parent must be an Enemy!")
		return

	# Wait for tree to be ready
	await get_tree().process_frame

	# Find player and grid system
	player = get_tree().get_first_node_in_group("player") as Player
	grid_system = get_tree().get_first_node_in_group("grid") as GridSystem

	if player == null:
		push_error("EnemyAI: Cannot find player in 'player' group!")

	if grid_system == null:
		push_error("EnemyAI: Cannot find grid system in 'grid' group!")


## Execute enemy turn.
## Returns true if the enemy took an action, false if turn is complete.
func execute_turn() -> bool:
	if enemy == null or player == null or grid_system == null:
		print("EnemyAI: Missing required references")
		return false

	# Validate both enemy and player are still alive
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		print("EnemyAI: Enemy or player is no longer valid")
		return false

	# Check if enemy can act
	if enemy.current_action_points <= 0:
		print("EnemyAI: No action points remaining")
		return false

	# Get current positions
	var current_tile: Vector2i = enemy.get_current_tile()
	var player_tile: Vector2i = player.get_current_tile()

	# Calculate distance to player (Manhattan distance)
	var distance: int = grid_system.get_tile_distance(current_tile, player_tile)

	# Check if player is within attack range
	if distance <= Constants.ATTACK_RANGE:
		print("EnemyAI: Player in attack range (distance: ", distance, "), attacking!")

		# Check if we can afford to attack
		if not enemy.can_afford_action(Constants.ATTACK_COST):
			print("EnemyAI: Cannot afford attack (need ", Constants.ATTACK_COST, " AP, have ", enemy.current_action_points, ")")
			return false

		# Spend AP and attack
		if enemy.spend_action_points(Constants.ATTACK_COST):
			enemy.attack_player(player)

			# Return true if we can still act
			return enemy.current_action_points > 0

		return false

	# Otherwise, move toward player using pathfinding
	# Find path to player (or as close as possible)
	var path: Array[Vector2i] = grid_system.find_path(current_tile, player_tile)

	if path.is_empty():
		print("EnemyAI: No path to player from ", current_tile, " to ", player_tile)
		return false

	# Remove current tile from path
	if path.size() > 0 and path[0] == current_tile:
		path.remove_at(0)

	# If no more tiles in path, we're at the player (shouldn't happen)
	if path.is_empty():
		print("EnemyAI: Already at player position")
		return false

	# Get next tile in path
	var next_tile: Vector2i = path[0]

	# Validate next tile is walkable
	if not grid_system.is_tile_walkable(next_tile):
		print("EnemyAI: Next tile ", next_tile, " is not walkable")
		return false

	# Calculate movement cost (1 AP per tile)
	var move_cost: int = 1

	# Check if we can afford to move
	if not enemy.can_afford_action(move_cost):
		print("EnemyAI: Cannot afford movement (need ", move_cost, " AP, have ", enemy.current_action_points, ")")
		return false

	# Spend AP and move
	if enemy.spend_action_points(move_cost):
		print("EnemyAI: Moving from ", current_tile, " to ", next_tile)
		enemy.move_to_tile(next_tile)

		# Wait for movement to complete
		await enemy.movement_completed

		# Return true if we can still act
		return enemy.current_action_points > 0

	return false
