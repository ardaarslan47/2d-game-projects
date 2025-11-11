# Adding Map Generation to Your Game Scene

## Errors Fixed ✅

1. **Integer division warning** - Fixed in `map_generator.gd:102`
2. **Missing MapGenerator node** - Made optional in `game_manager.gd`

Your game now runs without errors even without the MapGenerator node!

## How to Add Map Generation to Your Game

### Option 1: Using the Test Scene (Recommended for Testing)

1. Open Godot
2. Navigate to `scenes/test_map_generation.tscn`
3. Run the scene (F5)
4. Click "Generate New Map" to test (works with or without tileset imported)

### Option 2: Add to Main Game Scene

To add map generation to your existing game scene:

#### Step 1: Add Required Nodes to `scenes/game.tscn`

Open the scene in Godot and add these nodes:

```
game (Node2D)
├── ... (existing nodes)
├── TileMap (NEW - for terrain)
├── ObstacleContainer (NEW - Node2D for spawned obstacles)
└── MapGenerator (NEW - Node with map_generator.gd script)
```

#### Step 2: In Godot Editor

1. **Add TileMap**:
   - Right-click on `game` node → Add Child Node
   - Choose `TileMap`
   - Name it `TileMap`

2. **Add ObstacleContainer**:
   - Right-click on `game` node → Add Child Node
   - Choose `Node2D`
   - Name it `ObstacleContainer`

3. **Add MapGenerator**:
   - Right-click on `game` node → Add Child Node
   - Choose `Node`
   - Name it `MapGenerator`
   - In Inspector, attach script: `res://scripts/map_generator.gd`

4. **Configure MapGenerator**:
   - Select the `MapGenerator` node
   - In Inspector, you'll see exported properties:
     - `Tilemap`: Drag the `TileMap` node here
     - `Obstacle Container`: Drag the `ObstacleContainer` node here
     - `Map Width`: Set to desired size (e.g., 20)
     - `Map Height`: Set to desired size (e.g., 15)
     - `Obstacle Density`: 0.15 (15% coverage)
     - `Elevated Terrain Chance`: 0.3 (30% elevated tiles)

5. **Save the scene**

#### Step 3: Generate Map on Game Start

Add this to your `game_manager.gd` or create a new initialization script:

```gdscript
func _ready() -> void:
    # ... existing code ...

    # Setup map generation if available
    if map_generator != null:
        var obstacle_scenes: Array[PackedScene] = [
            load("res://scenes/obstacles/supply_crate.tscn"),
            load("res://scenes/obstacles/concrete_barrier.tscn")
        ]
        map_generator.set_obstacle_scenes(obstacle_scenes)

        # Generate map
        map_generator.generate_map()
```

### Option 3: Manual Scene File Edit (Advanced)

Alternatively, you can manually edit `scenes/game.tscn` to add:

```gdscript
[ext_resource type="Script" path="res://scripts/map_generator.gd" id="10_mapgen"]

# Add these nodes:
[node name="TileMap" type="TileMap" parent="."]
format = 2
layer_0/name = "Terrain"

[node name="ObstacleContainer" type="Node2D" parent="."]

[node name="MapGenerator" type="Node" parent="."]
script = ExtResource("10_mapgen")
map_width = 20
map_height = 15
obstacle_density = 0.15
elevated_terrain_chance = 0.3
```

Then connect references in the inspector.

## What Works Now

- ✅ Game runs without errors
- ✅ MapGenerator is optional
- ✅ Test scene is ready to use
- ✅ Obstacle scenes are created
- ✅ All scripts are functional

## What You Need Before Full Map Generation

1. **Tileset must be imported**:
   - Wait for tileset generation to complete
   - Download the tileset PNG
   - Import to Godot as TileSet
   - Configure Wang tiles in TileMap

2. **TileMap must be configured**:
   - Add TileSet resource to TileMap
   - Set tile size (32x32)
   - Configure collision layers if needed

## Testing Without Tileset

You can still test obstacle generation without the tileset:
1. Open `scenes/test_map_generation.tscn`
2. Run it
3. Obstacles will spawn (terrain tiles won't show until tileset is imported)

## Next Steps

1. ✅ Errors fixed - game runs
2. ⏳ Wait for tileset generation
3. 📥 Download tileset when ready
4. 🔧 Import tileset to Godot
5. ➕ Add MapGenerator nodes to game scene (use one of the options above)
6. 🎮 Test map generation!

## Need Help?

See `MAP_GENERATION_GUIDE.md` for complete documentation.
