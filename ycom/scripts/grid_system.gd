class_name GridSystem
extends Node2D

## Grid system for XCOM-like turn-based gameplay.
## Manages grid boundaries, tile validation, and coordinate conversions.
## No visual representation - pure logic layer for game mechanics.

# Signals
signal grid_initialized

# Exported variables
@export var grid_width: int = 20  ## Grid width in tiles
@export var grid_height: int = 15  ## Grid height in tiles

# Private variables
var _grid_data: Dictionary = {}  ## Stores tile data [Vector2i -> Dictionary]


func _ready() -> void:
	_initialize_grid()
	grid_initialized.emit()


## Check if a tile position is within grid bounds.
func is_valid_tile(tile_pos: Vector2i) -> bool:
	return (
		tile_pos.x >= 0 and tile_pos.x < grid_width and
		tile_pos.y >= 0 and tile_pos.y < grid_height
	)


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
## Returns empty dictionary if tile doesn't exist or is out of bounds.
func get_tile_data(tile_pos: Vector2i) -> Dictionary:
	if not is_valid_tile(tile_pos):
		return {}

	if not _grid_data.has(tile_pos):
		return {}

	return _grid_data[tile_pos]


## Set tile data at the specified position.
func set_tile_data(tile_pos: Vector2i, data: Dictionary) -> void:
	if not is_valid_tile(tile_pos):
		push_warning("GridSystem: Attempted to set data on invalid tile: %s" % tile_pos)
		return

	_grid_data[tile_pos] = data


## Check if a tile is walkable (not blocked by obstacle).
func is_tile_walkable(tile_pos: Vector2i) -> bool:
	if not is_valid_tile(tile_pos):
		return false

	var tile_data: Dictionary = get_tile_data(tile_pos)
	if tile_data.is_empty():
		return true  # Empty tiles are walkable by default

	return tile_data.get("walkable", true)


## Mark a tile as blocked or unblocked.
func set_tile_walkable(tile_pos: Vector2i, walkable: bool) -> void:
	if not is_valid_tile(tile_pos):
		return

	var tile_data: Dictionary = get_tile_data(tile_pos)
	tile_data["walkable"] = walkable
	set_tile_data(tile_pos, tile_data)


## Get all tiles within a certain range from a center tile.
## Uses Manhattan distance (XCOM-style movement).
func get_tiles_in_range(center: Vector2i, range: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []

	for x in range(-range, range + 1):
		for y in range(-range, range + 1):
			var tile_pos: Vector2i = center + Vector2i(x, y)
			var distance: int = abs(x) + abs(y)

			if distance <= range and is_valid_tile(tile_pos):
				tiles.append(tile_pos)

	return tiles


## Calculate Manhattan distance between two tiles.
func get_tile_distance(from: Vector2i, to: Vector2i) -> int:
	return abs(to.x - from.x) + abs(to.y - from.y)


## Get neighboring tiles (4 directions: up, down, left, right).
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
		if is_valid_tile(neighbor):
			neighbors.append(neighbor)

	return neighbors


## Get all neighboring tiles (8 directions including diagonals).
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
		if is_valid_tile(neighbor):
			neighbors.append(neighbor)

	return neighbors


## Clear all tile data.
func clear_grid_data() -> void:
	_grid_data.clear()


## Get the total number of tiles in the grid.
func get_total_tiles() -> int:
	return grid_width * grid_height


## Get grid dimensions as Vector2i.
func get_grid_size() -> Vector2i:
	return Vector2i(grid_width, grid_height)


# Private methods
func _initialize_grid() -> void:
	_grid_data.clear()
	print("GridSystem: Initialized %dx%d grid (%d total tiles)" % [grid_width, grid_height, get_total_tiles()])
