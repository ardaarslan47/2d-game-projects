class_name ChunkManager
extends Node2D

## Manages infinite procedural terrain generation using chunks.
## Loads and unloads chunks based on player position.

# Signals
signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

# Constants
const CHUNK_SIZE: int = 16  # Tiles per chunk (16x16)
const TILE_SIZE: int = 16   # Pixels per tile
const LOAD_RADIUS: int = 2  # Load chunks within this radius
const UNLOAD_RADIUS: int = 3  # Unload chunks beyond this radius

# Exported variables
@export var tilemap: TileMap
@export var player: Node2D
@export var terrain_generator: ProceduralTerrain

# Private variables
var _loaded_chunks: Dictionary = {}  # Vector2i -> bool
var _last_player_chunk: Vector2i = Vector2i.ZERO
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5  # Check every 0.5 seconds

func _ready() -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player == null:
		push_error("ChunkManager: No player found!")
		return

	# Auto-find children if not set
	if terrain_generator == null:
		terrain_generator = get_node_or_null("ProceduralTerrain")

	# Load initial chunks around player
	_update_chunks()

func _process(delta: float) -> void:
	_update_timer += delta

	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		_update_chunks()

func _update_chunks() -> void:
	if player == null:
		return

	var current_chunk: Vector2i = _world_to_chunk(player.global_position)

	# Only update if player moved to a different chunk
	if current_chunk == _last_player_chunk:
		return

	_last_player_chunk = current_chunk

	# Load new chunks
	_load_chunks_around(current_chunk)

	# Unload distant chunks
	_unload_distant_chunks(current_chunk)

func _load_chunks_around(center_chunk: Vector2i) -> void:
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk_pos: Vector2i = center_chunk + Vector2i(x, y)

			if not _loaded_chunks.has(chunk_pos):
				_load_chunk(chunk_pos)

func _load_chunk(chunk_pos: Vector2i) -> void:
	if _loaded_chunks.has(chunk_pos):
		return

	# Mark as loaded
	_loaded_chunks[chunk_pos] = true

	# Generate terrain for this chunk
	if terrain_generator:
		terrain_generator.generate_chunk(tilemap, chunk_pos, CHUNK_SIZE)

	chunk_loaded.emit(chunk_pos)

func _unload_distant_chunks(center_chunk: Vector2i) -> void:
	var chunks_to_unload: Array[Vector2i] = []

	# Find chunks that are too far
	for chunk_pos in _loaded_chunks.keys():
		var distance: int = max(
			abs(chunk_pos.x - center_chunk.x),
			abs(chunk_pos.y - center_chunk.y)
		)

		if distance > UNLOAD_RADIUS:
			chunks_to_unload.append(chunk_pos)

	# Unload them
	for chunk_pos in chunks_to_unload:
		_unload_chunk(chunk_pos)

func _unload_chunk(chunk_pos: Vector2i) -> void:
	if not _loaded_chunks.has(chunk_pos):
		return

	# Remove tiles in this chunk
	var start_tile: Vector2i = chunk_pos * CHUNK_SIZE

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos: Vector2i = start_tile + Vector2i(x, y)
			tilemap.erase_cell(0, tile_pos)  # Layer 0

	# Mark as unloaded
	_loaded_chunks.erase(chunk_pos)

	chunk_unloaded.emit(chunk_pos)

func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	var tile_pos: Vector2i = Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		int(floor(world_pos.y / TILE_SIZE))
	)

	return Vector2i(
		int(floor(float(tile_pos.x) / CHUNK_SIZE)),
		int(floor(float(tile_pos.y) / CHUNK_SIZE))
	)

func get_loaded_chunk_count() -> int:
	return _loaded_chunks.size()
