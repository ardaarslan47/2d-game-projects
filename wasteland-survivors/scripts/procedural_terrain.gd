class_name ProceduralTerrain
extends Node

## Generates procedural terrain using noise.
## Creates natural-looking grass patterns with variations.

# Exported variables
@export var seed_value: int = 12345
@export var noise_scale: float = 0.1  # Lower = larger features
@export var grass_threshold: float = 0.3  # Above this = grass variation

# Private variables
var _noise: FastNoiseLite

func _ready() -> void:
	_setup_noise()

func _setup_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = seed_value
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = noise_scale
	_noise.fractal_octaves = 3
	_noise.fractal_lacunarity = 2.0
	_noise.fractal_gain = 0.5

func generate_chunk(tilemap: TileMap, chunk_pos: Vector2i, chunk_size: int) -> void:
	if tilemap == null:
		push_error("ProceduralTerrain: TileMap is null!")
		return

	var start_tile: Vector2i = chunk_pos * chunk_size

	for x in range(chunk_size):
		for y in range(chunk_size):
			var tile_pos: Vector2i = start_tile + Vector2i(x, y)
			var tile_atlas_coords: Vector2i = _get_tile_for_position(tile_pos)

			# Place tile on layer 0
			tilemap.set_cell(0, tile_pos, 0, tile_atlas_coords)

func _get_tile_for_position(tile_pos: Vector2i) -> Vector2i:
	# Get noise value at this position
	var noise_value: float = _noise.get_noise_2d(float(tile_pos.x), float(tile_pos.y))

	# Normalize noise from [-1, 1] to [0, 1]
	noise_value = (noise_value + 1.0) / 2.0

	# The grass tileset appears to be a 16x16 grid
	# We'll use noise to randomly select tiles across the entire tileset

	# Use noise to determine tile coordinates
	var tile_x: int = int(noise_value * 16.0) % 16

	# Get a second noise value with an offset for y coordinate
	var noise_value_y: float = _noise.get_noise_2d(float(tile_pos.x + 1000), float(tile_pos.y + 1000))
	noise_value_y = (noise_value_y + 1.0) / 2.0
	var tile_y: int = int(noise_value_y * 16.0) % 16

	return Vector2i(tile_x, tile_y)

func set_seed(new_seed: int) -> void:
	seed_value = new_seed
	_setup_noise()

func get_noise_value(world_pos: Vector2) -> float:
	if _noise == null:
		return 0.0

	var noise_val: float = _noise.get_noise_2d(world_pos.x, world_pos.y)
	return (noise_val + 1.0) / 2.0  # Normalize to [0, 1]
