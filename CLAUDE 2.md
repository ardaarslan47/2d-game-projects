# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Wasteland Survivors

A post-apocalyptic top-down horde survivor game with game-breaking synergies, built in Godot 4.5.

**Genre**: Vampire Survivors-like (top-down, auto-firing weapons, wave-based enemy spawning)
**Engine**: Godot 4.5
**Language**: GDScript
**Status**: Production-ready with XP/leveling, multi-stage progression, object pooling, and complete UI

---

## Running the Game

```bash
# Launch Godot editor
mcp__godot__launch_editor --projectPath="/Users/ardaarslan/Documents/2d-game-projects/wasteland-survivors"

# Run the game
mcp__godot__run_project --projectPath="/Users/ardaarslan/Documents/2d-game-projects/wasteland-survivors"

# Check debug output
mcp__godot__get_debug_output

# Stop running game
mcp__godot__stop_project
```

**Main scene**: `res://scenes/game.tscn`
**Window size**: 1280x720 (fullscreen mode 2)

---

## Architecture Overview

### Core Systems

**1. GameManager Autoload (Singleton)**
- **Location**: `scripts/autoload/game_manager.gd`
- **Purpose**: Central game state controller
- **Responsibilities**:
  - Game time tracking (elapsed seconds)
  - Multi-stage progression (5 minutes per stage)
  - Exponential difficulty scaling
  - Performance caps to prevent overwhelming gameplay
- **Key Signals**:
  - `game_time_changed(elapsed_seconds)` - Every second
  - `difficulty_level_changed(level)` - Every 30 seconds
  - `stage_completed(stage)` - Every 5 minutes
- **Access Pattern**: `GameManager.get_current_time()`, `GameManager.start_next_stage()`

**Difficulty Scaling Formulas**:
```gdscript
# Health scaling (exponential growth)
scaled_health = base_health * (1 + minutes)^1.5 * stage_multiplier

# Spawn rate scaling (5% every 30s, capped at 5x)
spawn_rate_multiplier = min(1.0 + (difficulty_level * 0.05), 5.0)

# Speed scaling (10% every 2 minutes, capped at 2x)
speed_multiplier = min(1.0 + (minutes / 2.0 * 0.1), 2.0)

# Stage multiplier (exponential per stage)
stage_multiplier = 2^(stage - 1)
```

**Why Capped**: Spawn rate and speed caps prevent impossible difficulty while health can scale infinitely to reward weapon upgrades.

**2. Object Pooling System**
- **Purpose**: Eliminate GC pressure and instantiation lag during gameplay
- **Implementation**: `EnemyPool` and `ProjectilePool` classes
- **Pattern**: Pre-warm → Get from pool → Use → Return to pool
- **Pool Sizes**:
  - Enemies: 20 initial, 50 max per enemy type
  - Projectiles: 20 initial, 50 max
- **Key Methods**:
  - `get_enemy()` / `get_projectile()` - Returns deactivated instance
  - `return_to_pool()` - Called automatically on death/despawn
  - `reset_state()` - Resets object to initial state

**Integration**: `EnemyBase` and `Projectile` have built-in pool support. Set pool reference with `set_pool()`.

**3. Infinite Procedural World (Chunk-based)**
- `ChunkManager` (`scripts/chunk_manager.gd`) orchestrates world generation
- `ProceduralTerrain` (`scripts/procedural_terrain.gd`) generates terrain using FastNoiseLite
- Chunks are 16×16 tiles, tiles are 16px each
- Load radius: 2 chunks, Unload radius: 3 chunks
- Updates every 0.5 seconds based on player position
- Uses Perlin noise with 3 octaves for natural terrain variation

**4. Component-Based Architecture**
- `WeaponManager` component handles multiple active weapons (attached to Player)
- `HealthComponent` is a reusable health system (used by Player and Enemies)
- Weapons inherit from `WeaponBase` and auto-fire at nearest target
- Enemies inherit from `EnemyBase` with chase AI

**5. Player System**
- 8-directional top-down movement with acceleration/friction
- Directional animations: "up", "down", "side" (with flip_h for left/right)
- Invincibility frames with visual feedback (red flash + blinking)
- Knockback on hit
- `HealthComponent` for health management
- `WeaponManager` child node for weapon handling
- XP collection and leveling with upgrade selection

**6. Weapon System**
- All weapons extend `WeaponBase` and auto-fire
- Two weapon types:
  - **Ranged** (Rusty Pistol): Fires projectiles at targets
  - **Melee** (Rusty Sword): Cone-shaped hitbox with speed-reactive detection
- `WeaponRegistry` resource maps weapon names to scripts
- Target acquisition: finds nearest enemy within `weapon_range`
- Multi-shot: sequential firing with 0.05s delays
- Per-weapon upgrade system (damage, fire rate, range, pierce, multi-shot, etc.)

**7. Enemy System**
- `EnemySpawner` spawns enemies around player using object pools
- All enemies extend `EnemyBase` with chase AI
- Two enemy types:
  - **Zombie**: Base enemy (60 speed, 100 health)
  - **Zombie Cat**: Fast enemy (100 speed, 50 health, spawns in pairs during time windows)
- Hitbox Area2D triggers melee attacks with cooldown
- Difficulty scaling via GameManager
- Enemy limit: 50 concurrent enemies
- Spawn distance: 600px from player

**8. XP and Progression System**
- Enemies drop XP shards on death
- XP shards auto-collected by player
- Exponential XP requirement: `base_xp * 1.2^level`
- Level-up triggers upgrade menu with 3 random choices
- Each upgrade has 2 stats specific to an active weapon
- Upgrades apply multipliers to weapon stats

**9. UI System**
- **HUD**: Health bar, XP bar, timer, level, stage indicators
- **PauseMenu**: Escape to pause, resume/quit buttons
- **LevelUpMenu**: 3 upgrade choices per level-up
- **GameOverScreen**: Final stats (time, kills, level), restart/quit
- **LevelCompleteScreen**: Stage completion stats, next level button
- **Coordinator Pattern**: `game.gd` mediates between player and UI via signals

**10. Prop Spawning**
- `PropSpawner` decorates chunks with static props
- Props placed based on noise patterns for natural distribution

---

## Key Design Patterns

### GameManager Singleton Pattern
```gdscript
# Access from anywhere
var current_time: float = GameManager.get_current_time()
var stage: int = GameManager.current_stage

# Connect to signals
GameManager.stage_completed.connect(_on_stage_completed)
```

### Object Pool Pattern
```gdscript
# Setup pool in game.gd
@onready var zombie_pool: EnemyPool = $ZombiePool

# Get enemy from pool
var enemy: EnemyBase = zombie_pool.get_enemy()
enemy.global_position = spawn_position

# Return to pool (automatic in EnemyBase after death animation)
enemy._return_to_pool()
```

### Resource Registry Pattern
```gdscript
# WeaponRegistry resource
@export var weapon_registry: WeaponRegistry

# Get weapon script dynamically
var weapon_script: Script = weapon_registry.get_weapon_script("Rusty Pistol")
```

### Component Pattern
```gdscript
# HealthComponent usage
@onready var health_component: HealthComponent = $HealthComponent

# Connect signals
health_component.health_changed.connect(_on_health_changed)
health_component.died.connect(_on_died)

# Use methods
health_component.take_damage(10)
```

### UI Coordinator Pattern (game.gd)
```gdscript
# Signal flow: Player → game.gd → UI
player.level_up.connect(_on_player_level_up)
func _on_player_level_up(level: int) -> void:
	level_up_menu.show_menu(player.weapon_manager.get_active_weapons())

# Signal flow: UI → game.gd → Player
level_up_menu.upgrade_selected.connect(_on_upgrade_selected)
func _on_upgrade_selected(upgrade: Dictionary) -> void:
	player.apply_upgrade(upgrade)
```

### Player Hierarchy
```
Player (CharacterBody2D)
├── AnimatedSprite2D (directional animations)
├── CollisionShape2D
├── HealthComponent (health management)
└── WeaponManager (Node)
	├── WeaponPistol (WeaponBase) [dynamically added]
	└── WeaponSword (WeaponBase) [dynamically added]
```

### Weapon Inheritance
```
WeaponBase (Node2D) - Base class with auto-fire logic
├── WeaponPistol (ranged projectile weapon)
└── WeaponSword (melee cone hitbox weapon)
```

### Enemy Hierarchy
```
EnemyBase (CharacterBody2D) - Chase AI + HealthComponent + melee attack + pool support
├── EnemyZombie (base enemy type)
└── EnemyZombieCat (fast enemy with time-window spawning)
```

### Scene Hierarchy (game.tscn)
```
Game (Node2D)
├── TileMap (terrain rendering)
├── ChunkManager (Node2D)
│   └── ProceduralTerrain (Node)
├── PropSpawner (Node2D)
├── Player (CharacterBody2D)
│   ├── Camera2D (follows player)
│   ├── HealthComponent
│   └── WeaponManager (Node)
├── EnemySpawner (Node2D)
├── ProjectilePool (Node)
├── ZombiePool (EnemyPool)
├── ZombieCatPool (EnemyPool)
├── HUD (CanvasLayer)
├── LevelUpMenu (CanvasLayer)
├── GameOverScreen (CanvasLayer)
├── LevelCompleteScreen (CanvasLayer)
└── PauseMenu (CanvasLayer)
```

---

## Important Implementation Details

### Stage Progression System
**Flow**:
1. Each stage lasts 5 minutes (GameManager tracks time)
2. `GameManager.stage_completed` signal emitted at 5:00
3. `game.gd` pauses game tree, shows `LevelCompleteScreen`
4. Player clicks "Next Level"
5. `game.gd` clears all enemies (returns to pools)
6. `GameManager.start_next_stage()` resets timer, increases stage multiplier
7. Game resumes with exponentially harder enemies

**Stage Multiplier Impact**: Each stage doubles enemy health (stage 2 = 2x, stage 3 = 4x, stage 4 = 8x).

### XP and Upgrade Workflow
**Flow**:
1. Enemy dies → spawns XP shard at death position
2. XP shard auto-collects when player nearby
3. Player XP increases, triggers `xp_changed` signal → updates HUD
4. XP reaches threshold → triggers `level_up` signal
5. `game.gd` receives signal → pauses game → shows `LevelUpMenu`
6. `LevelUpMenu` generates 3 random upgrades from active weapons
7. Each upgrade shows weapon icon + 2 stat improvements
8. Player selects upgrade → emits `upgrade_selected` signal
9. `game.gd` passes upgrade to `player.apply_upgrade()`
10. Player finds weapon by name, applies stat multipliers
11. Menu hides, game resumes

**Upgrade Stats by Weapon**:
- **Rusty Pistol**: Damage, Fire Rate, Range, Pierce, Multi-Shot, Projectile Size
- **Rusty Sword**: Damage, Fire Rate, Range, Multi-Shot, Cone Angle

### Movement and Physics
- Player uses `move_and_slide()` in `_physics_process`
- Input via `Input.get_vector("left", "right", "up", "down")`
- Direction normalized for consistent diagonal speed
- Knockback overrides normal movement temporarily
- Animation system: vertical movement must be 1.5x stronger than horizontal to use up/down animation

### Weapon Targeting and Firing

**Ranged Weapons (Pistol)**:
- Targets nearest enemy within weapon range
- Fires projectiles from player position
- Multi-shot fires at different targets sequentially (0.05s delay)
- Projectiles spawned via `ProjectilePool.get_projectile()`

**Melee Weapons (Sword)**:
- Speed-reactive detection: `detection_range = base_range * 1.3 + (enemy_speed * 0.6)`
- Prevents fast enemies from feeling unfair
- Cone-shaped hitbox instantiated at player position
- Hits all enemies in cone (pierce = all)
- Knockback applied on hit

**Weapon Access Pattern**:
```gdscript
# Weapons find player by traversing hierarchy
var weapon_manager: WeaponManager = get_parent()
var player: CharacterBody2D = weapon_manager.get_parent()
```

### Enemy AI and Spawning
- Enemies always chase player (simple AI)
- Find player via `get_tree().get_first_node_in_group("player")`
- Hitbox Area2D detects collision with player for melee attacks
- Attack cooldown prevents continuous damage
- Health scaling via `GameManager.get_scaled_health(base_health)`
- Speed scaling via `GameManager.get_speed_multiplier()`

**Zombie Cat Time Windows**:
- Spawns during odd minutes (1:00-1:30, 3:00-3:30, etc.)
- Spawns in pairs for predictable difficulty spikes
- 66% faster than regular zombies
- 50% health of regular zombies

### Chunk Management
- Chunks indexed by Vector2i (chunk coordinates)
- World position → Tile position → Chunk position conversion
- `_loaded_chunks` Dictionary tracks loaded chunks
- Chunks generate all tiles at once (16×16 = 256 tiles per chunk)
- TileMap layer 0 used for all terrain

### Group System
- `"player"` group: Player node
- `"enemies"` group: All enemies
- `"xp_shards"` group: XP pickups

### Utility Classes

**GameConstants** (`scripts/constants/game_constants.gd`):
- Centralizes configuration values
- Eliminates magic numbers
- Categories: player animations, hit effects, chunk settings, difficulty scaling

**NodeUtils** (`scripts/utilities/node_utils.gd`):
- Safe node access patterns
- `is_valid(node)` - Null and instance validity
- `safe_queue_free(node)` - Safe cleanup
- `safe_call(node, method, args)` - Method existence checking
- `get_first_in_group(group)` - Null-safe group access

**Usage**: Import and use throughout codebase to prevent crashes from freed nodes.

### Signal Architecture

**Player Signals**:
- `health_changed(current_health, max_health)`
- `died`
- `xp_changed(current_xp, xp_to_next_level)`
- `level_up(new_level)`

**GameManager Signals**:
- `game_time_changed(elapsed_seconds)`
- `difficulty_level_changed(level)`
- `stage_completed(stage)`

**UI Signals**:
- `LevelUpMenu.upgrade_selected(upgrade_data)`
- `LevelCompleteScreen.next_level_requested`

**WeaponManager Signals**:
- `weapon_added(weapon)`
- `weapon_removed(weapon)`

**HealthComponent Signals**:
- `health_changed(current, max)`
- `damage_taken(amount)`
- `healed(amount)`
- `died`

---

## Asset Organization

```
assets/
├── tilesets/
│   └── Grass.png (16×16 tile grid)
├── characters/
│   └── player/ (AnimatedSprite2D frames)
└── enemies/
	├── zombie/ (AnimatedSprite2D frames)
	└── zombie_cat/ (AnimatedSprite2D frames)

scenes/
├── game.tscn (main scene)
├── characters/
│   └── player.tscn
├── enemies/
│   ├── zombie.tscn
│   └── zombie_cat.tscn
├── weapons/
│   ├── projectile.tscn
│   └── sword_hitbox.tscn
├── pickups/
│   └── xp_shard.tscn
└── ui/
	├── hud.tscn
	├── level_up_menu.tscn
	├── game_over_screen.tscn
	├── level_complete_screen.tscn
	└── pause_menu.tscn

scripts/
├── autoload/
│   └── game_manager.gd       # Singleton
├── constants/
│   └── game_constants.gd     # Configuration
├── utilities/
│   └── node_utils.gd         # Helper functions
├── components/
│   ├── weapon_manager.gd     # Player weapon system
│   └── health_component.gd   # Reusable health
├── weapons/
│   ├── weapon_pistol.gd      # Ranged weapon
│   └── weapon_sword.gd       # Melee weapon
├── enemies/
│   ├── enemy_zombie.gd       # Base enemy
│   └── enemy_zombie_cat.gd   # Fast enemy
├── pickups/
│   └── xp_shard.gd           # XP collectible
├── ui/
│   ├── hud.gd
│   ├── level_up_menu.gd
│   ├── game_over_screen.gd
│   ├── level_complete_screen.gd
│   └── pause_menu.gd
├── game.gd                   # Main coordinator
├── player.gd
├── chunk_manager.gd
├── procedural_terrain.gd
├── enemy_spawner.gd
├── prop_spawner.gd
├── weapon_base.gd
├── projectile.gd
├── enemy_base.gd
├── enemy_pool.gd             # Enemy pooling
├── projectile_pool.gd        # Projectile pooling
├── weapon_registry.gd        # Weapon registry resource
└── sword_hitbox.gd           # Sword hitbox logic
```

---

## Input Map (Project Settings)

Already configured:
- `left`: A, Left Arrow
- `right`: D, Right Arrow
- `up`: W, Up Arrow
- `down`: S, Down Arrow
- `pause`: Escape

---

## Common Development Workflows

### Adding a New Weapon

**Ranged Weapon**:
1. Create script in `scripts/weapons/` extending `WeaponBase`
2. Override exported variables (damage, fire_rate, weapon_range, etc.)
3. Implement `_fire_at_target()` to spawn projectiles via `projectile_pool`
4. Add to `WeaponRegistry` resource in editor
5. Add to player via `weapon_manager.add_weapon_by_name("Weapon Name")`

**Melee Weapon**:
1. Create script in `scripts/weapons/` extending `WeaponBase`
2. Create hitbox scene (Area2D with CollisionShape2D)
3. Override `_fire_at_target()` to instantiate hitbox
4. Implement hitbox logic to detect and damage enemies
5. Add to `WeaponRegistry` resource in editor

**Example**:
```gdscript
# scripts/weapons/weapon_shotgun.gd
class_name WeaponShotgun
extends WeaponBase

func _init() -> void:
	weapon_name = "Shotgun"
	base_damage = 15.0
	base_fire_rate = 1.0
	projectile_count = 5
	weapon_range = 300.0
	projectile_spread = 30.0
```

### Adding a New Enemy Type

1. Create scene in `scenes/enemies/` (CharacterBody2D + AnimatedSprite2D + CollisionShape2D + Hitbox Area2D)
2. Create script in `scripts/enemies/` extending `EnemyBase`
3. Override stats (base_max_health, base_move_speed, base_damage, attack_cooldown)
4. Add AnimatedSprite2D with "walk" and "side" animations
5. Create object pool in `game.tscn` (EnemyPool node)
6. Set pool's enemy scene to your new enemy
7. Update `EnemySpawner` to reference the new pool and spawn the enemy

**Example**:
```gdscript
# scripts/enemies/enemy_fast_zombie.gd
class_name EnemyFastZombie
extends EnemyBase

func _init() -> void:
    base_max_health = 75.0
    base_move_speed = 120.0
    base_damage = 15.0
    attack_cooldown = 1.2
```

### Adding Per-Weapon Upgrade Stats

1. Open `scripts/ui/level_up_menu.gd`
2. Add new stat to `_get_available_stats_for_weapon()` match statement
3. Define stat data: name, description, icon
4. Implement stat application in weapon script's `upgrade_stat()` method

**Example**:
```gdscript
# In level_up_menu.gd
"Shotgun":
	stats = ["Damage", "Fire Rate", "Spread", "Pellet Count"]

# In weapon_shotgun.gd
func upgrade_stat(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Pellet Count":
			projectile_count = int(projectile_count * multiplier)
```

### Integrating Object Pooling for New Entity

1. Create pool class extending generic pool pattern (see `enemy_pool.gd`)
2. Implement `_create_new_instance()` to instantiate entity
3. Add `set_pool()` method to entity script
4. Add `_return_to_pool()` method called on despawn
5. Add `reset_state()` method to entity to reset all state variables
6. Create pool node in `game.tscn`, set scene property
7. Pass pool reference to systems that spawn the entity

### Modifying Difficulty Scaling

**Edit GameManager.gd**:
```gdscript
# Change health scaling exponent
func get_scaled_health(base_health: float) -> float:
	return base_health * pow(1 + minutes, 2.0) * stage_multiplier  # Changed from 1.5 to 2.0

# Change spawn rate scaling
func _update_difficulty() -> void:
	spawn_rate_multiplier = min(1.0 + (difficulty_level * 0.1), 5.0)  # Changed from 0.05 to 0.1
```

### Modifying Terrain Generation
- Edit `ProceduralTerrain._get_tile_for_position()` for tile selection logic
- Adjust noise parameters: `noise_scale`, `seed_value`, fractal settings
- Modify `ChunkManager` constants: `CHUNK_SIZE`, `LOAD_RADIUS`, `UNLOAD_RADIUS`

### Testing Stage Progression
1. Run game
2. Set `GameManager.STAGE_DURATION` to 10.0 (10 seconds) for faster testing
3. Observe stage transitions and difficulty scaling
4. Check `LevelCompleteScreen` shows correct stats
5. Restore `STAGE_DURATION` to 300.0 (5 minutes) when done

---

## Known Patterns and Conventions

### Type Hints
All variables and functions use strict type hints (enforced by project style).

### Scene vs Script Organization
- Simple entities: Script-only (e.g., `WeaponManager`, `ChunkManager`, `GameManager`)
- Complex entities: Scene + Script (e.g., `Player`, `Enemy`, UI screens)

### Autoload Usage
**Current Autoloads**:
- `GameManager` - Game state, time, difficulty, stages

**When to Add Autoload**:
- Only for truly global systems needed everywhere
- Avoid for systems that can be passed via references
- Examples: AudioManager, EventBus (if needed)

### Resource-Based Configuration
- `WeaponRegistry` uses @export resource pattern
- Allows editor-based management
- Supports runtime registration

### Safe Node Access
**Always use NodeUtils for node operations**:
```gdscript
# Instead of:
if node and is_instance_valid(node):
	node.queue_free()

# Use:
NodeUtils.safe_queue_free(node)
```

### Private Methods
Prefix with underscore: `_handle_input()`, `_spawn_enemy()`, `_load_chunk()`, `_return_to_pool()`

### Deferred Operations
Use `set_deferred()` and `call_deferred()` for node operations during physics:
```gdscript
# Prevents "busy node" errors
collision_shape.set_deferred("disabled", true)
get_parent().call_deferred("add_child", new_node)
```

---

## Implementation Status

**Core Features**:
- ✅ Player movement (8-direction, smooth)
- ✅ Multiple weapon system (pistol + sword) with registry
- ✅ Enemy spawning with variety (zombie + zombie cat)
- ✅ Infinite procedural terrain (chunk-based)
- ✅ Health system with HealthComponent (invincibility frames, knockback)
- ✅ XP/leveling system (exponential scaling)
- ✅ Weapon upgrade system (per-weapon stat multipliers)
- ✅ Object pooling (enemies + projectiles)
- ✅ Multi-stage progression (5-minute stages)
- ✅ Difficulty scaling (exponential with caps)
- ✅ Complete UI suite (HUD, pause, level-up, game-over, level-complete)
- ✅ GameManager singleton (time, difficulty, stages)
- ✅ Prop spawning

**Known Issues**:
- ⚠️ XP shard `body_entered` signal not connected in scene (XP shards spawn but aren't collectible - needs signal connection)
- ⚠️ Kill counter not incremented (UI exists but no tracking - needs enemy death counter)

**Future Enhancements** (not yet implemented):
- Save/load system for progression
- More weapon types (shotgun, laser, explosives)
- More enemy types (ranged enemies, tanks, special abilities)
- Boss encounters
- Power-up synergies and meta-progression
- Audio system (SFX, music)

---

## Performance Considerations

### Object Pooling Benefits
- Eliminates GC pressure during gameplay
- Pre-warming prevents allocation spikes
- Caps prevent unlimited memory growth
- Significant FPS improvement at high enemy counts

### Difficulty Caps
- **Spawn Rate**: Capped at 5x to prevent overwhelming spawns and framerate drops
- **Speed**: Capped at 2x to prevent enemies from "teleporting" visually
- **Health**: Uncapped to allow endless scaling (rewards weapon upgrades)

### Chunk Management
- Updates every 0.5 seconds (not every frame) to reduce load
- Load/unload radius prevents constant chunk churn
- Chunks remain loaded until outside unload radius (hysteresis)

### Deferred Child Operations
- All child additions use `call_deferred()` to prevent frame spikes
- Collision shape changes use `set_deferred()` to avoid physics errors

---

## Debugging Tips

### Common Issues
1. **Chunks not loading**: Check player node is in "player" group
2. **Weapons not firing**: Verify `WeaponManager` is child of Player, check `weapon_registry` is assigned
3. **Enemies not spawning**: Check max_enemies limit, spawn_distance, and pool sizes
4. **Projectiles not hitting**: Verify collision layers/masks
5. **Performance drops**: Check loaded chunk count, enemy count, and pool sizes
6. **UI not showing**: Check CanvasLayer visibility and process_mode (should handle pause)
7. **XP not collecting**: Check XP shard signal connections (known issue)
8. **Upgrades not applying**: Verify weapon name matches exactly in upgrade data

### Debug Commands
```gdscript
# Print loaded chunks
print(chunk_manager.get_loaded_chunk_count())

# Print active enemies
print(get_tree().get_nodes_in_group("enemies").size())

# Print pool stats
print("Zombie Pool: ", zombie_pool.get_active_count(), "/", zombie_pool.pool.size())
print("Projectile Pool: ", projectile_pool.get_active_count(), "/", projectile_pool.pool.size())

# Print player position and chunk
print("Player: ", player.global_position, " Chunk: ", chunk_manager._last_player_chunk)

# Print game state
print("Stage: ", GameManager.current_stage, " Time: ", GameManager.get_current_time())
print("Difficulty: ", GameManager.difficulty_level)

# Print weapon stats
for weapon in player.weapon_manager.get_active_weapons():
    print(weapon.weapon_name, " - Damage: ", weapon.damage, " FireRate: ", weapon.fire_rate)
```

### Testing Shortcuts
```gdscript
# Speed up stage testing (in game_manager.gd)
const STAGE_DURATION: float = 10.0  # Normally 300.0 (5 minutes)

# Speed up leveling (in player.gd)
const BASE_XP_TO_LEVEL: float = 10.0  # Normally 100.0

# Test specific enemy types (in enemy_spawner.gd)
# Comment out time-based logic, spawn only desired type
```

---

## Rendering Settings

- `textures/canvas_textures/default_texture_filter=0` (nearest neighbor for pixel art)
- Canvas items stretch mode
- Fullscreen mode 2 (windowed fullscreen)
