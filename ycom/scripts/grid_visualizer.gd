extends Node2D

## Grid visualizer for chunk-based XCOM-like turn-based gameplay.
## Handles visual feedback: grid lines, movement range, attack range, tile highlights.
## Works with infinite chunk-based grid system.

# Player modes
enum PlayerMode {
	MOVE,    # Show movement range
	ATTACK   # Show attack range
}

# Visual colors
const COLOR_GRID_LINES: Color = Color(0.2, 0.2, 0.2, 0.3)  # Dark gray grid
const COLOR_MOVEMENT_RANGE: Color = Color(0.3, 0.6, 1.0, 0.4)  # Blue for movement
const COLOR_ATTACK_RANGE: Color = Color(1.0, 0.3, 0.3, 0.4)  # Red for attack
const COLOR_HOVER_TILE: Color = Color(1.0, 1.0, 1.0, 0.6)  # White hover
const COLOR_HOVER_BORDER: Color = Color(1.0, 1.0, 1.0, 1.0)  # White border
const COLOR_INVALID_TILE: Color = Color(0.5, 0.5, 0.5, 0.3)  # Gray for blocked

# Exported settings
@export var show_grid_lines: bool = true
@export var show_range_indicators: bool = true
@export var show_hover_highlight: bool = true
@export var grid_line_width: float = 1.0

# Current player mode
var current_mode: PlayerMode = PlayerMode.MOVE

# Node references
var grid_system: GridSystem = null
var player: Player = null

# Visual state
var movement_range_tiles: Array[Vector2i] = []
var attack_range_tiles: Array[Vector2i] = []
var hover_tile: Vector2i = Vector2i(-1, -1)
var hover_tile_info: Dictionary = {}


func _ready() -> void:
	# Set z-index to render above ground but below characters
	z_index = -5

	# Find grid system
	grid_system = get_tree().get_first_node_in_group("grid") as GridSystem
	if grid_system == null:
		push_error("GridVisualizer: Cannot find GridSystem!")
		return

	# Find player
	player = get_tree().get_first_node_in_group("player") as Player
	if player == null:
		push_error("GridVisualizer: Cannot find Player!")
		return

	# Connect to player signals
	if player.has_signal("movement_completed"):
		player.movement_completed.connect(_on_player_moved)
	if player.has_signal("action_points_changed"):
		player.action_points_changed.connect(_on_player_ap_changed)

	print("GridVisualizer: Initialized for chunk-based grid")


func _process(_delta: float) -> void:
	if grid_system == null or player == null:
		return

	# Update hover tile
	_update_hover_tile()

	# Request redraw every frame
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Toggle between move and attack mode with Tab key
	if event.is_action_pressed("ui_focus_next"):  # Tab key
		toggle_mode()


func _draw() -> void:
	if grid_system == null:
		return

	# Draw grid lines for loaded chunks
	if show_grid_lines:
		_draw_grid_lines_for_chunks()

	# Draw range indicators based on current mode
	if show_range_indicators:
		match current_mode:
			PlayerMode.MOVE:
				_draw_movement_range()
			PlayerMode.ATTACK:
				_draw_attack_range()

	# Draw hover tile and info
	if show_hover_highlight and hover_tile != Vector2i(-1, -1):
		_draw_hover_tile()


# ========================================
# Mode Management
# ========================================

## Toggle between move and attack modes.
func toggle_mode() -> void:
	if current_mode == PlayerMode.MOVE:
		current_mode = PlayerMode.ATTACK
		print("GridVisualizer: Switched to ATTACK mode")
	else:
		current_mode = PlayerMode.MOVE
		print("GridVisualizer: Switched to MOVE mode")

	update_range_indicators()


## Set the current mode explicitly.
func set_mode(mode: PlayerMode) -> void:
	if current_mode != mode:
		current_mode = mode
		print("GridVisualizer: Mode set to ", "MOVE" if mode == PlayerMode.MOVE else "ATTACK")
		update_range_indicators()


## Get current mode.
func get_mode() -> PlayerMode:
	return current_mode


# ========================================
# Range Visualization
# ========================================

## Update movement and attack range indicators.
func update_range_indicators() -> void:
	if player == null or grid_system == null:
		return

	var player_tile: Vector2i = player.get_current_tile()
	var action_points: int = player.get_action_points()

	# Calculate movement range (tiles within AP range)
	movement_range_tiles = grid_system.get_tiles_in_range(player_tile, action_points)
	movement_range_tiles.erase(player_tile)  # Don't highlight player's tile

	# Calculate attack range (tiles within attack range from player)
	var attack_range: int = Constants.ATTACK_RANGE if Constants else 1
	attack_range_tiles = grid_system.get_tiles_in_range(player_tile, attack_range)
	attack_range_tiles.erase(player_tile)

	queue_redraw()


## Clear all range indicators.
func clear_range_indicators() -> void:
	movement_range_tiles.clear()
	attack_range_tiles.clear()
	queue_redraw()


# ========================================
# Hover Tile Management
# ========================================

## Update hover tile based on mouse position.
func _update_hover_tile() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var tile: Vector2i = grid_system.world_to_tile(mouse_pos)

	# Check if this is a valid tile position
	var chunk_pos: Vector2i = grid_system.tile_to_chunk(tile)
	if grid_system.is_chunk_loaded(chunk_pos):
		hover_tile = tile
		_update_hover_tile_info()
	else:
		hover_tile = Vector2i(-1, -1)
		hover_tile_info.clear()


## Update information about the hovered tile.
func _update_hover_tile_info() -> void:
	if hover_tile == Vector2i(-1, -1) or player == null:
		hover_tile_info.clear()
		return

	hover_tile_info.clear()

	# Tile coordinates
	hover_tile_info["coords"] = hover_tile

	# Distance from player (Manhattan distance)
	var player_tile: Vector2i = player.get_current_tile()
	var distance: int = grid_system.get_tile_distance(player_tile, hover_tile)
	hover_tile_info["distance"] = distance

	# Action point cost (assume 1 AP per tile for now)
	hover_tile_info["ap_cost"] = distance

	# Tile state
	var state: int = grid_system.get_tile_state(hover_tile)
	var state_str: String = "Empty"
	if state & GridSystem.TileState.PLAYER:
		state_str = "Player"
	elif state & GridSystem.TileState.ENEMY:
		state_str = "Enemy"
	elif state & GridSystem.TileState.OBSTACLE:
		state_str = "Obstacle"

	hover_tile_info["state"] = state_str
	hover_tile_info["walkable"] = grid_system.is_tile_walkable(hover_tile)


# ========================================
# Drawing Methods
# ========================================

## Draw grid lines for all loaded chunks.
func _draw_grid_lines_for_chunks() -> void:
	var loaded_chunks: Array[Vector2i] = grid_system.get_loaded_chunks()
	var tile_size: float = Constants.TILE_SIZE

	for chunk_pos in loaded_chunks:
		var origin: Vector2i = grid_system.chunk_to_tile_origin(chunk_pos)
		var chunk_size: int = GridSystem.CHUNK_SIZE

		# Draw vertical lines for this chunk
		for x in range(chunk_size + 1):
			var tile_x: int = origin.x + x
			var start_y: int = origin.y
			var end_y: int = origin.y + chunk_size

			var start: Vector2 = Vector2(tile_x * tile_size, start_y * tile_size)
			var end: Vector2 = Vector2(tile_x * tile_size, end_y * tile_size)
			draw_line(start, end, COLOR_GRID_LINES, grid_line_width)

		# Draw horizontal lines for this chunk
		for y in range(chunk_size + 1):
			var tile_y: int = origin.y + y
			var start_x: int = origin.x
			var end_x: int = origin.x + chunk_size

			var start: Vector2 = Vector2(start_x * tile_size, tile_y * tile_size)
			var end: Vector2 = Vector2(end_x * tile_size, tile_y * tile_size)
			draw_line(start, end, COLOR_GRID_LINES, grid_line_width)


## Draw movement range tiles.
func _draw_movement_range() -> void:
	var tile_size: float = Constants.TILE_SIZE

	for tile in movement_range_tiles:
		var world_pos: Vector2 = grid_system.tile_to_world(tile)
		var rect: Rect2 = Rect2(
			world_pos.x - tile_size / 2.0,
			world_pos.y - tile_size / 2.0,
			tile_size,
			tile_size
		)

		# Check if tile is walkable
		var color: Color = COLOR_MOVEMENT_RANGE if grid_system.is_tile_walkable(tile) else COLOR_INVALID_TILE
		draw_rect(rect, color, true)


## Draw attack range tiles.
func _draw_attack_range() -> void:
	var tile_size: float = Constants.TILE_SIZE

	for tile in attack_range_tiles:
		var world_pos: Vector2 = grid_system.tile_to_world(tile)
		var rect: Rect2 = Rect2(
			world_pos.x - tile_size / 2.0,
			world_pos.y - tile_size / 2.0,
			tile_size,
			tile_size
		)

		# Show attack range regardless of walkability
		draw_rect(rect, COLOR_ATTACK_RANGE, true)


## Draw hover tile with info overlay.
func _draw_hover_tile() -> void:
	var tile_size: float = Constants.TILE_SIZE
	var world_pos: Vector2 = grid_system.tile_to_world(hover_tile)
	var rect: Rect2 = Rect2(
		world_pos.x - tile_size / 2.0,
		world_pos.y - tile_size / 2.0,
		tile_size,
		tile_size
	)

	# Draw hover highlight
	draw_rect(rect, COLOR_HOVER_TILE, true)

	# Draw border
	draw_rect(rect, COLOR_HOVER_BORDER, false, 2.0)

	# Draw tile info text (if we have info)
	if not hover_tile_info.is_empty():
		_draw_tile_info_text(world_pos)


## Draw tile information text near hover position.
func _draw_tile_info_text(world_pos: Vector2) -> void:
	if hover_tile_info.is_empty():
		return

	var font_size: int = 12
	var offset: Vector2 = Vector2(20, -20)  # Offset from tile center
	var line_height: float = font_size + 4

	# Build info text
	var info_lines: Array[String] = []

	# Tile coordinates
	if hover_tile_info.has("coords"):
		var coords: Vector2i = hover_tile_info["coords"]
		info_lines.append("Tile: (%d, %d)" % [coords.x, coords.y])

	# AP cost
	if hover_tile_info.has("ap_cost"):
		info_lines.append("AP Cost: %d" % hover_tile_info["ap_cost"])

	# Tile state
	if hover_tile_info.has("state"):
		var state_str: String = hover_tile_info["state"]
		var walkable: bool = hover_tile_info.get("walkable", true)
		info_lines.append("State: %s%s" % [state_str, " (Blocked)" if not walkable else ""])

	# Draw background panel
	var panel_width: float = 150
	var panel_height: float = line_height * info_lines.size() + 8
	var panel_pos: Vector2 = world_pos + offset
	var panel_rect: Rect2 = Rect2(panel_pos, Vector2(panel_width, panel_height))

	draw_rect(panel_rect, Color(0.1, 0.1, 0.1, 0.9), true)  # Dark background
	draw_rect(panel_rect, Color(1.0, 1.0, 1.0, 0.5), false, 1.0)  # White border

	# Draw text lines
	var text_pos: Vector2 = panel_pos + Vector2(4, font_size + 2)
	for line in info_lines:
		draw_string(ThemeDB.fallback_font, text_pos, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
		text_pos.y += line_height


# ========================================
# Signal Handlers
# ========================================

## Called when player completes movement.
func _on_player_moved() -> void:
	update_range_indicators()


## Called when player's action points change.
func _on_player_ap_changed(_current_ap: int, _max_ap: int) -> void:
	update_range_indicators()
