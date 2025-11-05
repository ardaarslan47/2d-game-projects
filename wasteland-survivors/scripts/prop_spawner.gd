class_name PropSpawner
extends Node2D

## Spawns props (plants, bushes, etc.) in chunks.
## Uses procedural generation to place decorative objects.

# Exported variables
@export var plant_texture: Texture2D
@export var spawn_density: float = 0.05  # Probability per tile (5%)
@export var seed_value: int = 54321

# Private variables
var _rng: RandomNumberGenerator
var _chunk_props: Dictionary = {}  # Vector2i (chunk) -> Array[Node2D]

# Plant sprite frame positions in the texture
# Based on the plant.png asset structure
const TREE_FRAMES: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)  # Three large trees
]
const BUSH_FRAMES: Array[Vector2i] = [
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),  # Medium bushes
	Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)
]
const SMALL_PLANT_FRAMES: Array[Vector2i] = [
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)  # Small plants
]

# Sizes based on asset
const TREE_SIZE: Vector2i = Vector2i(48, 64)
const BUSH_SIZE: Vector2i = Vector2i(24, 24)
const SMALL_PLANT_SIZE: Vector2i = Vector2i(16, 16)

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value

func spawn_props_in_chunk(chunk_pos: Vector2i, chunk_size: int, tile_size: int) -> void:
	if plant_texture == null:
		return

	var props: Array[Node2D] = []
	var start_tile: Vector2i = chunk_pos * chunk_size

	# Use chunk position as seed for consistent generation
	_rng.seed = hash(Vector2(chunk_pos.x, chunk_pos.y)) + seed_value

	for x in range(chunk_size):
		for y in range(chunk_size):
			if _rng.randf() < spawn_density:
				var tile_pos: Vector2i = start_tile + Vector2i(x, y)
				var world_pos: Vector2 = Vector2(tile_pos) * tile_size

				var prop: Node2D = _create_prop(world_pos)
				if prop:
					add_child(prop)
					props.append(prop)

	_chunk_props[chunk_pos] = props

func _create_prop(world_pos: Vector2) -> Node2D:
	# Randomly choose prop type
	var prop_type: int = _rng.randi_range(0, 2)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = plant_texture
	sprite.centered = false
	sprite.global_position = world_pos

	var frame_data: Dictionary

	match prop_type:
		0:  # Tree (30% chance, larger)
			if _rng.randf() < 0.3:
				frame_data = _get_frame_data(TREE_FRAMES, TREE_SIZE)
				sprite.z_index = 1
			else:
				frame_data = _get_frame_data(BUSH_FRAMES, BUSH_SIZE)
		1:  # Bush (most common)
			frame_data = _get_frame_data(BUSH_FRAMES, BUSH_SIZE)
		2:  # Small plant
			frame_data = _get_frame_data(SMALL_PLANT_FRAMES, SMALL_PLANT_SIZE)

	# Set up sprite region
	sprite.region_enabled = true
	sprite.region_rect = frame_data.rect

	# Center the sprite
	var size: Vector2i = frame_data.size
	sprite.offset = -Vector2(size.x / 2.0, size.y / 2.0)

	return sprite

func _get_frame_data(frames: Array[Vector2i], size: Vector2i) -> Dictionary:
	var frame: Vector2i = frames[_rng.randi_range(0, frames.size() - 1)]

	return {
		"rect": Rect2(frame.x * size.x, frame.y * size.y, size.x, size.y),
		"size": size
	}

func remove_props_in_chunk(chunk_pos: Vector2i) -> void:
	if not _chunk_props.has(chunk_pos):
		return

	var props: Array[Node2D] = _chunk_props[chunk_pos]

	for prop in props:
		if is_instance_valid(prop):
			prop.queue_free()

	_chunk_props.erase(chunk_pos)

func get_prop_count() -> int:
	var count: int = 0
	for props in _chunk_props.values():
		count += props.size()
	return count
