# Random Map Generation Guide

## Overview
This guide explains how to use the random map generation system for your X-COM-like tactical game.

## Generated Assets

### Tileset
- **Tileset ID**: `db26b188-c339-4272-9588-382585860816`
- **Lower Terrain**: Concrete floor with battle damage and scorch marks
- **Upper Terrain**: Reinforced metal platform with tactical grid lines
- **Transition**: Damaged metal edge with exposed concrete
- **Status**: Processing (~100 seconds total)

Check status with:
```bash
# Once ready, download will be available
```

### Obstacles
1. **Supply Crate** (64x64px) - ✅ Downloaded
   - Scene: `scenes/obstacles/supply_crate.tscn`
   - Asset: `assets/obstacles/supply_crate.png`
   - Cover bonus: 30%
   - Health: 50
   - Destructible: Yes

2. **Concrete Barrier** (96x64px) - ✅ Downloaded
   - Scene: `scenes/obstacles/concrete_barrier.tscn`
   - Asset: `assets/obstacles/concrete_barrier.png`
   - Cover bonus: 40%
   - Health: 100
   - Destructible: Yes

## System Components

### 1. MapGenerator Script (`scripts/map_generator.gd`)
Main script that handles:
- Wang tileset-based terrain generation
- Random obstacle placement
- Seed-based reproducibility

**Key Features:**
- Generates terrain using vertex-based Wang tiles (for natural transitions)
- Places obstacles with configurable density
- Avoids placing obstacles near edges
- Prevents obstacle overlap

**Configurable Properties:**
```gdscript
@export var map_width: int = 20
@export var map_height: int = 20
@export var obstacle_density: float = 0.15  # 15% of tiles
@export var elevated_terrain_chance: float = 0.3  # 30% elevated
```

### 2. Obstacle Script (`scripts/obstacle.gd`)
Base class for all obstacles with:
- Movement blocking
- Cover system (defense bonus)
- Destructible option
- Health system

## Setup Instructions

### Step 1: Wait for Tileset Generation
The tileset takes ~100 seconds to generate. Check status periodically:
```gdscript
# Will provide download URL when ready
```

### Step 2: Import Tileset to Godot

Once the tileset is downloaded:

1. **Download the tileset PNG**:
   - Use the curl command or download URL provided
   - Save to `assets/tilesets/tactical_terrain.png`

2. **Read Wang Tileset Documentation**:
   ```gdscript
   # Must read the Godot implementation guide
   # Available at: pixellab://docs/godot/wang-tilesets
   ```

3. **Create TileMap in Godot**:
   - Add a `TileMap` node to your game scene
   - Create a new TileSet resource
   - Import the tileset PNG
   - Configure the Wang tiles according to the documentation

4. **Set up collision layers**:
   - Elevated terrain tiles should have collision shapes
   - Lower terrain tiles are walkable

### Step 3: Add MapGenerator to Scene

Update your main game scene (`scenes/game.tscn`):

```
Game (Node2D)
├── TileMap (for generated terrain)
├── ObstacleContainer (Node2D - holds spawned obstacles)
├── MapGenerator (Node with map_generator.gd script)
│   └── Configure references:
│       - tilemap: points to TileMap node
│       - obstacle_container: points to ObstacleContainer
├── Player
├── Enemies (container)
└── ... (other nodes)
```

### Step 4: Configure MapGenerator

In the Godot inspector for MapGenerator node:
1. Drag TileMap node to `tilemap` property
2. Drag ObstacleContainer to `obstacle_container` property
3. Adjust `map_width`, `map_height`, `obstacle_density` as desired

### Step 5: Load Obstacle Scenes

Add to your game initialization code:

```gdscript
# In game_manager.gd or similar
func _ready() -> void:
    # Load obstacle scenes
    var obstacle_scenes: Array[PackedScene] = [
        load("res://scenes/obstacles/supply_crate.tscn"),
        load("res://scenes/obstacles/concrete_barrier.tscn")
    ]

    # Pass to map generator
    if map_generator != null:
        map_generator.set_obstacle_scenes(obstacle_scenes)
        map_generator.generate_map()
```

### Step 6: Generate Map

Call generation manually or on game start:

```gdscript
# Generate with random seed
map_generator.generate_map()

# Or generate with specific seed (for reproducible maps)
map_generator.generate_with_seed(12345)
```

## Usage Examples

### Example 1: Generate New Map on Game Start
```gdscript
func _ready() -> void:
    # Setup obstacle scenes
    var obstacles: Array[PackedScene] = [
        load("res://scenes/obstacles/supply_crate.tscn"),
        load("res://scenes/obstacles/concrete_barrier.tscn")
    ]
    map_generator.set_obstacle_scenes(obstacles)

    # Generate map
    map_generator.generate_map()
```

### Example 2: Regenerate Map with Button Press
```gdscript
func _on_regenerate_button_pressed() -> void:
    map_generator.generate_map()
    print("New map generated with seed: ", map_generator.map_seed)
```

### Example 3: Load Specific Map Seed
```gdscript
func load_mission(mission_seed: int) -> void:
    map_generator.generate_with_seed(mission_seed)
    # Same seed = same map layout
```

## Wang Tileset Explanation

The generated tileset uses the **Wang blob tiling algorithm**:

### How It Works
1. **Vertices define terrain**: Each grid vertex has a terrain type (0 or 1)
2. **Tiles sample 4 corners**: Each tile checks its 4 corner vertices
3. **Tile index calculation**:
   - NW corner = bit 0 (value 1)
   - NE corner = bit 1 (value 2)
   - SW corner = bit 2 (value 4)
   - SE corner = bit 3 (value 8)
   - Total index = sum (0-15 for 16 tiles)

### Example
```
Vertex grid (0=lower, 1=upper):
0 1 1
1 1 0
0 0 0

Tile at position (0,0) samples corners:
- NW = 0, NE = 1, SW = 1, SE = 1
- Index = 0×1 + 1×2 + 1×4 + 1×8 = 14
- Use tile #14 from tileset
```

This creates seamless terrain transitions automatically!

## Customization

### Add More Obstacle Types
1. Generate more props with PixelLab:
   ```gdscript
   mcp__pixellab__create_map_object(
       description="your obstacle description",
       width=64,
       height=64
   )
   ```

2. Download the asset
3. Create a scene file (copy pattern from existing obstacles)
4. Add to obstacle_scenes array

### Adjust Map Parameters
```gdscript
# Larger maps
map_generator.map_width = 30
map_generator.map_height = 30

# More obstacles
map_generator.obstacle_density = 0.25  # 25%

# More varied terrain
map_generator.elevated_terrain_chance = 0.5  # 50%
```

### Create Connected Tilesets
Use the base tile IDs to create multi-terrain maps:
- Lower base tile ID: `94b003ee-d9cf-47c2-a0b3-d4f163ecf300`
- Upper base tile ID: `2ed50a43-be4d-40cc-9884-ad5ab741b339`

Example:
```gdscript
# Create a second tileset that connects to the first
mcp__pixellab__create_topdown_tileset(
    lower_base_tile_id="2ed50a43-be4d-40cc-9884-ad5ab741b339",  # Use upper as new lower
    upper_description="rocky mountain terrain"
)
```

## Integration with Gameplay

### Movement System
The grid system already handles tile-based movement. Obstacles automatically block movement via collision layers.

### Cover System
Obstacles provide cover bonuses in combat:
```gdscript
# In combat calculation
var cover_bonus: int = 0
if obstacle_between_attacker_and_target:
    cover_bonus = obstacle.cover_bonus  # e.g., 30%

var hit_chance: int = base_chance - cover_bonus
```

### Destructible Obstacles
Obstacles can be destroyed during combat:
```gdscript
# When explosion hits obstacle
obstacle.take_damage(50)
# If health reaches 0, obstacle is removed
```

## Next Steps

1. ✅ MapGenerator script created
2. ✅ Obstacle script created
3. ✅ Obstacle scenes created
4. ⏳ Wait for tileset generation (~100 seconds)
5. 📥 Download tileset when ready
6. 🔧 Import tileset to Godot TileMap
7. 🎮 Add MapGenerator to game scene
8. ✨ Test map generation!

## Troubleshooting

### Tileset not showing correctly
- Check that Wang tiles are configured in tileset resource
- Verify atlas coordinates match the 4x4 grid layout
- Read the PixelLab Wang tileset documentation

### Obstacles not spawning
- Check that `obstacle_scenes` array is set
- Verify `obstacle_container` reference is connected
- Ensure scenes load correctly (check console for errors)

### Obstacles overlap or spawn at edges
- Adjust `obstacle_density` lower
- Check border exclusion logic in `_place_obstacles()`

### Map doesn't match seed
- Ensure you call `seed(map_seed)` before generation
- Verify no external random calls between seeding and generation
