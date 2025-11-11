# Quick Start: Map Generation

## What's Been Created

### ✅ Scripts
1. **`scripts/map_generator.gd`** - Main map generation system
   - Wang tileset-based terrain generation
   - Random obstacle placement
   - Seed-based reproducibility

2. **`scripts/obstacle.gd`** - Base obstacle class
   - Movement blocking
   - Cover system
   - Destructible functionality

3. **`scripts/test_map_scene.gd`** - Test scene controller

### ✅ Scenes
1. **`scenes/obstacles/supply_crate.tscn`** - Supply crate obstacle
2. **`scenes/obstacles/concrete_barrier.tscn`** - Concrete barrier obstacle
3. **`scenes/test_map_generation.tscn`** - Test/demo scene

### ✅ Assets Downloaded
1. **`assets/obstacles/supply_crate.png`** - 64x64px crate sprite
2. **`assets/obstacles/concrete_barrier.png`** - 96x64px barrier sprite

### ⏳ Assets Generating
1. **Tileset** (ID: `db26b188-c339-4272-9588-382585860816`)
   - Status: Processing (~100 seconds total)
   - 16 Wang tiles for seamless terrain transitions
   - Lower: Concrete floor with battle damage
   - Upper: Metal platform with tactical grid

## Next Steps (After Tileset is Ready)

### 1. Check Tileset Status
Run in terminal or check periodically:
```bash
# The tileset should be ready soon (takes ~100 seconds from generation start)
```

### 2. Download Tileset
Once ready, you'll receive a download URL. Save it to:
```
assets/tilesets/tactical_terrain.png
```

### 3. Import to Godot
1. Open Godot editor
2. The PNG will auto-import
3. Create a TileSet resource in your TileMap
4. Add the tileset PNG as source
5. Configure Wang tiles (see full guide for details)

### 4. Test Map Generation
1. Open `scenes/test_map_generation.tscn` in Godot
2. Run the scene (F5)
3. Click "Generate New Map" button
4. Map will generate with:
   - Terrain tiles (once tileset is imported)
   - Random obstacles (supply crates and barriers)

### 5. Integrate into Main Game
Add MapGenerator node to your main game scene:
```gdscript
# In game_manager.gd _ready()
var obstacles: Array[PackedScene] = [
    load("res://scenes/obstacles/supply_crate.tscn"),
    load("res://scenes/obstacles/concrete_barrier.tscn")
]
map_generator.set_obstacle_scenes(obstacles)
map_generator.generate_map()
```

## Quick Configuration

### Change Map Size
```gdscript
map_generator.map_width = 30
map_generator.map_height = 20
```

### Change Obstacle Density
```gdscript
map_generator.obstacle_density = 0.25  # 25% coverage
```

### Use Specific Seed
```gdscript
map_generator.generate_with_seed(12345)  # Same seed = same map
```

## Files to Read
- **`MAP_GENERATION_GUIDE.md`** - Complete documentation
- **`scripts/map_generator.gd`** - Implementation details
- **PixelLab Wang Tileset Docs** - How to set up tilesets in Godot

## Troubleshooting
See MAP_GENERATION_GUIDE.md for detailed troubleshooting.

Quick fixes:
- **No obstacles?** Check that scene files exist in inspector
- **No terrain?** Tileset needs to be imported and configured
- **Errors in console?** Check node references in map_generator
