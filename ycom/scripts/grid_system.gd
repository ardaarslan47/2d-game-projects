class_name GridSystem
extends Node2D

## Grid system for XCOM-like turn-based gameplay.
## Manages tile validation and coordinate conversions.
## No visual representation - pure logic layer for game mechanics.
## Uses infinite/boundless grid - no size restrictions.
## Uses bitflag-based tile state system for modular tile occupancy tracking.

# Signals
signal grid_initialized
signal tile_state_changed(tile_pos: Vector2i, old_state: int, new_state: int)
signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

# Tile state bitflags - can be combined with bitwise OR (|)
enum TileState {
	EMPTY = 0,         # 0b0000 - No occupants
	PLAYER = 1,        # 0b0001 - Player occupies this tile
	ENEMY = 2,         # 0b0010 - Enemy occupies this tile
	OBSTACLE = 4,      # 0b0100 - Static obstacle blocks this tile
}

# Chunk system constants
const CHUNK_SIZE: int = 16  ## Tiles per chunk (16x16)
const CHUNK_LOAD_RADIUS: int = 3  ## Load chunks within this radius of player (7x7 area = 49 chunks)

# Private variables
var _grid_data: Dictionary = {}  ## Stores tile data [Vector2i -> Dictionary]
var _tile_states: Dictionary = {}  ## Stores tile states [Vector2i -> int (bitflags)]
var _loaded_chunks: Dictionary = {}  ## Stores loaded chunks [Vector2i -> Chunk]
var _player_current_chunk: Vector2i = Vector2i.ZERO  ## Track player's chunk position


func _ready() -> void:
	_initialize_grid()
	grid_initialized.emit()


func _process(_delta: float) -> void:
	# Update chunk loading based on player position
	_update_chunk_loading()


# ========================================
# Tile State Management (Bitflag System)
# ========================================

## Get the current state of a tile.
## Returns TileState bitflags (0 = empty).
## Automatically loads chunk if needed.
func get_tile_state(tile_pos: Vector2i) -> int:
	# Ensure chunk is loaded
	var chunk_pos: Vector2i = tile_to_chunk(tile_pos)
	if not is_chunk_loaded(chunk_pos):
		load_chunk(chunk_pos)

	return _tile_states.get(tile_pos, TileState.EMPTY)


## Set the complete state of a tile (replaces existing state).
## Use bitflags: grid.set_tile_state(pos, TileState.ENEMY | TileState.OBSTACLE)
## Automatically loads chunk if needed.
func set_tile_state(tile_pos: Vector2i, state: int) -> void:
	# Ensure chunk is loaded
	var chunk_pos: Vector2i = tile_to_chunk(tile_pos)
	if not is_chunk_loaded(chunk_pos):
		load_chunk(chunk_pos)

	var old_state: int = _tile_states.get(tile_pos, TileState.EMPTY)

	if old_state == state:
		return  # No change

	_tile_states[tile_pos] = state

	tile_state_changed.emit(tile_pos, old_state, state)


## Add state flag(s) to a tile (keeps existing flags).
## Example: grid.add_tile_state(pos, TileState.ENEMY)
func add_tile_state(tile_pos: Vector2i, state_flag: int) -> void:
	var current_state: int = get_tile_state(tile_pos)
	set_tile_state(tile_pos, current_state | state_flag)


## Remove state flag(s) from a tile (keeps other flags).
## Example: grid.remove_tile_state(pos, TileState.ENEMY)
func remove_tile_state(tile_pos: Vector2i, state_flag: int) -> void:
	var current_state: int = get_tile_state(tile_pos)
	set_tile_state(tile_pos, current_state & ~state_flag)


## Check if a tile has specific state flag(s).
## Example: if grid.has_tile_state(pos, TileState.ENEMY):
func has_tile_state(tile_pos: Vector2i, state_flag: int) -> bool:
	return (get_tile_state(tile_pos) & state_flag) != 0


## Clear all states from a tile (set to EMPTY).
func clear_tile_state(tile_pos: Vector2i) -> void:
	set_tile_state(tile_pos, TileState.EMPTY)


## Clear all tile states in the grid.
func clear_all_tile_states() -> void:
	_tile_states.clear()


# ========================================
# Chunk Management
# ========================================

## Convert tile position to chunk position.
func tile_to_chunk(tile_pos: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(tile_pos.x) / CHUNK_SIZE),
		floori(float(tile_pos.y) / CHUNK_SIZE)
	)


## Convert chunk position to world position (chunk origin in world space).
func chunk_to_world(chunk_pos: Vector2i) -> Vector2:
	return Vector2(
		chunk_pos.x * CHUNK_SIZE * Constants.TILE_SIZE,
		chunk_pos.y * CHUNK_SIZE * Constants.TILE_SIZE
	)


## Get the tile position of the chunk's origin (top-left tile).
func chunk_to_tile_origin(chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		chunk_pos.x * CHUNK_SIZE,
		chunk_pos.y * CHUNK_SIZE
	)


## Check if a chunk is loaded.
func is_chunk_loaded(chunk_pos: Vector2i) -> bool:
	return _loaded_chunks.has(chunk_pos)


## Load a chunk at the specified chunk position.
func load_chunk(chunk_pos: Vector2i) -> void:
	if is_chunk_loaded(chunk_pos):
		return  # Already loaded

	# Create chunk data structure
	var chunk_data: Dictionary = {
		"position": chunk_pos,
		"tile_states": {},  # Local tile states for this chunk
		"generated": false
	}

	_loaded_chunks[chunk_pos] = chunk_data

	# Generate chunk content (procedural generation hook)
	_generate_chunk(chunk_pos, chunk_data)
	chunk_data["generated"] = true

	chunk_loaded.emit(chunk_pos)


## Unload a chunk at the specified chunk position.
func unload_chunk(chunk_pos: Vector2i) -> void:
	if not is_chunk_loaded(chunk_pos):
		return

	# Clear tile states for this chunk
	var chunk_data: Dictionary = _loaded_chunks[chunk_pos]
	var origin: Vector2i = chunk_to_tile_origin(chunk_pos)

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos: Vector2i = origin + Vector2i(x, y)
			# Only clear dynamic states (keep OBSTACLE if it's permanent terrain)
			_tile_states.erase(tile_pos)

	_loaded_chunks.erase(chunk_pos)
	chunk_unloaded.emit(chunk_pos)


## Get all currently loaded chunk positions.
func get_loaded_chunks() -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	for chunk_pos in _loaded_chunks.keys():
		chunks.append(chunk_pos)
	return chunks


# ========================================
# Tile Validation
# ========================================

## Check if a tile position is valid for gameplay.
## A tile is invalid if it has blocking states (PLAYER, ENEMY, or OBSTACLE).
func is_valid_tile(tile_pos: Vector2i) -> bool:
	# Ensure chunk is loaded
	var chunk_pos: Vector2i = tile_to_chunk(tile_pos)
	if not is_chunk_loaded(chunk_pos):
		load_chunk(chunk_pos)

	var state: int = get_tile_state(tile_pos)
	# Tile is invalid if it has any blocking states
	return (state & (TileState.PLAYER | TileState.ENEMY | TileState.OBSTACLE)) == 0


## Convert world position to tile coordinates.
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / Constants.TILE_SIZE)),
		int(floor(world_pos.y / Constants.TILE_SIZE))
	)


## Convert tile coordinates to world position (centered in tile).
func tile_to_world(tile_pos: Vector2i) -> Vector2:
	return Vector2(
		tile_pos.x * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0,
		tile_pos.y * Constants.TILE_SIZE + Constants.TILE_SIZE / 2.0
	)


## Get tile data at the specified position.
## Returns empty dictionary if tile doesn't exist.
func get_tile_data(tile_pos: Vector2i) -> Dictionary:
	if not _grid_data.has(tile_pos):
		return {}

	return _grid_data[tile_pos]


## Set tile data at the specified position.
func set_tile_data(tile_pos: Vector2i, data: Dictionary) -> void:
	_grid_data[tile_pos] = data


## Check if a tile is walkable (not blocked by any state).
## Tiles are walkable if they don't have PLAYER, ENEMY, or OBSTACLE states.
func is_tile_walkable(tile_pos: Vector2i) -> bool:
	return is_valid_tile(tile_pos)


## Get all tiles within a certain range from a center tile.
## Uses Manhattan distance (XCOM-style movement).
func get_tiles_in_range(center: Vector2i, max_distance: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []

	for x in range(-max_distance, max_distance + 1):
		for y in range(-max_distance, max_distance + 1):
			var tile_pos: Vector2i = center + Vector2i(x, y)
			var distance: int = abs(x) + abs(y)

			if distance <= max_distance:
				tiles.append(tile_pos)

	return tiles


## Calculate Manhattan distance between two tiles.
func get_tile_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(to.x - from.x) + abs(to.y - from.y)


## Get neighboring tiles (4 directions: up, down, left, right).
## No boundary checks - returns all 4 neighbors.
func get_neighbors(tile_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	for direction in directions:
		var neighbor: Vector2i = tile_pos + direction
		neighbors.append(neighbor)

	return neighbors


## Get all neighboring tiles (8 directions including diagonals).
## No boundary checks - returns all 8 neighbors.
func get_neighbors_8dir(tile_pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),   # Up
		Vector2i(0, 1),    # Down
		Vector2i(-1, 0),   # Left
		Vector2i(1, 0),    # Right
		Vector2i(-1, -1),  # Up-Left
		Vector2i(1, -1),   # Up-Right
		Vector2i(-1, 1),   # Down-Left
		Vector2i(1, 1)     # Down-Right
	]

	for direction in directions:
		var neighbor: Vector2i = tile_pos + direction
		neighbors.append(neighbor)

	return neighbors


## Clear all tile data.
func clear_grid_data() -> void:
	_grid_data.clear()


## Find path from start to goal using A* pathfinding.
## Returns Array[Vector2i] containing the path (including start and goal).
## Returns empty array if no path found.
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	# Validate that goal is walkable
	if not is_tile_walkable(goal):
		print("GridSystem: Goal tile is not walkable")
		return []

	# If start equals goal, return single-tile path
	if start == goal:
		return [start]

	# A* data structures
	var open_set: Array[Vector2i] = [start]
	var came_from: Dictionary = {}  # tile -> previous tile
	var g_score: Dictionary = {}    # tile -> cost from start
	var f_score: Dictionary = {}    # tile -> estimated total cost

	# Initialize scores
	g_score[start] = 0
	f_score[start] = _heuristic(start, goal)

	while not open_set.is_empty():
		# Get tile with lowest f_score
		var current: Vector2i = _get_lowest_f_score(open_set, f_score)

		# Check if we reached the goal
		if current == goal:
			return _reconstruct_path(came_from, current)

		# Remove current from open set
		open_set.erase(current)

		# Check all neighbors
		for neighbor in get_neighbors(current):
			# Skip unwalkable tiles
			if not is_tile_walkable(neighbor):
				continue

			# Calculate tentative g_score
			var tentative_g_score: int = g_score[current] + 1

			# If this path to neighbor is better than any previous one
			if not g_score.has(neighbor) or tentative_g_score < g_score[neighbor]:
				# Record best path
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g_score
				f_score[neighbor] = g_score[neighbor] + _heuristic(neighbor, goal)

				# Add neighbor to open set if not already there
				if neighbor not in open_set:
					open_set.append(neighbor)

	# No path found
	print("GridSystem: No path found from ", start, " to ", goal)
	return []


# Private methods
## Heuristic function for A* (Manhattan distance).
func _heuristic(from: Vector2i, to: Vector2i) -> int:
	return get_tile_distance(from, to)


## Get the tile with the lowest f_score from the open set.
func _get_lowest_f_score(open_set: Array[Vector2i], f_score: Dictionary) -> Vector2i:
	var lowest_tile: Vector2i = open_set[0]
	var lowest_score: int = f_score.get(lowest_tile, INF)

	for tile in open_set:
		var score: int = f_score.get(tile, INF)
		if score < lowest_score:
			lowest_score = score
			lowest_tile = tile

	return lowest_tile


## Reconstruct path from came_from dictionary.
func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]

	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)

	return path



func _initialize_grid() -> void:
	_grid_data.clear()
	_tile_states.clear()
	_loaded_chunks.clear()
	print("GridSystem: Initialized boundless chunk-based grid system (chunk size: %dx%d, load radius: %d)" % [CHUNK_SIZE, CHUNK_SIZE, CHUNK_LOAD_RADIUS])


## Update chunk loading based on player position.
## Called every frame to ensure chunks around player are loaded.
func _update_chunk_loading() -> void:
	# Find player
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if player_node == null:
		return

	# Get player's chunk position
	var player_tile: Vector2i
	if player_node.has_method("get_current_tile"):
		player_tile = player_node.get_current_tile()
	else:
		var player_world_pos: Vector2 = player_node.global_position
		player_tile = world_to_tile(player_world_pos)

	var player_chunk: Vector2i = tile_to_chunk(player_tile)

	# Check if player changed chunks
	if player_chunk == _player_current_chunk:
		return  # No chunk change, no need to update

	_player_current_chunk = player_chunk

	# Calculate which chunks should be loaded
	var required_chunks: Array[Vector2i] = []
	for x in range(-CHUNK_LOAD_RADIUS, CHUNK_LOAD_RADIUS + 1):
		for y in range(-CHUNK_LOAD_RADIUS, CHUNK_LOAD_RADIUS + 1):
			var chunk_pos: Vector2i = player_chunk + Vector2i(x, y)
			required_chunks.append(chunk_pos)

	# Load new chunks that aren't loaded
	for chunk_pos in required_chunks:
		if not is_chunk_loaded(chunk_pos):
			load_chunk(chunk_pos)

	# Unload chunks that are too far away
	var chunks_to_unload: Array[Vector2i] = []
	for chunk_pos in _loaded_chunks.keys():
		if chunk_pos not in required_chunks:
			chunks_to_unload.append(chunk_pos)

	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)


## Override this method to implement procedural generation for chunks.
## Called when a new chunk is loaded.
## chunk_pos: The chunk's position in chunk coordinates
## chunk_data: Dictionary with chunk information (you can store custom data here)
func _generate_chunk(chunk_pos: Vector2i, chunk_data: Dictionary) -> void:
	# Default implementation: initialize all tiles as EMPTY
	# Override this method in a subclass or modify this function to add:
	# - Procedural terrain generation
	# - Enemy spawning
	# - Obstacle placement
	# - Item spawning

	var origin: Vector2i = chunk_to_tile_origin(chunk_pos)

	# Initialize all tiles in this chunk to EMPTY (default state)
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos: Vector2i = origin + Vector2i(x, y)
			# By default, tiles are EMPTY (state = 0)
			# No need to explicitly set EMPTY state, it's implicit

			# Example: You can add generation logic here
			# if randf() < 0.1:  # 10% chance for obstacle
			#     set_tile_state(tile_pos, TileState.OBSTACLE)

	# Store any chunk-specific metadata in chunk_data if needed
	chunk_data["biome"] = "default"  # Example: you could determine biome here
