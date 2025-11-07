# Wasteland Survivors

A high-performance top-down horde survivor game showcasing advanced Godot architecture patterns and optimization techniques.

## Game Concept

Post-apocalyptic Vampire Survivors-like where players fight endless waves of enemies with auto-firing weapons. Features exponential difficulty scaling, multi-stage progression with boss encounters, and a deep upgrade system with game-breaking synergies.

**Genre:** Action | Horde Survivor | Top-Down
**Engine:** Godot 4.5
**Language:** GDScript (100% type-hinted)

---

## Technical Highlights

### Performance Optimization
- **Object Pooling System** - Custom pool implementation for enemies and projectiles eliminates GC pressure
  - Pre-warming: 20 instances per pool
  - Max capacity: 50 instances with auto-expansion
  - Automatic return-to-pool on death/despawn
  - Result: Stable 60 FPS with 50+ enemies and 30+ projectiles

- **Chunk-Based Procedural Terrain** - Infinite world generation with intelligent loading
  - 16×16 tile chunks with hysteresis (load radius: 2, unload radius: 3)
  - FastNoiseLite with 3 octaves for natural terrain variation
  - Update interval: 0.5s (not per-frame) to reduce overhead

- **Difficulty Scaling with Performance Caps**
  ```gdscript
  # Health scales infinitely (rewards upgrades)
  scaled_health = base_health * pow(1 + minutes, 1.5) * stage_multiplier

  # Spawn rate capped at 5x (prevents frame drops)
  spawn_rate = min(1.05^(time/30), 5.0) * stage_multiplier

  # Speed capped at 2x (prevents visual teleporting)
  speed = min(1.0 + (minutes/2 * 0.1), 2.0) * stage_multiplier
  ```

### Architecture Patterns

**Component-Based Design**
- `HealthComponent` - Reusable health system with signals (used by player + all enemies)
- `WeaponManager` - Dynamic weapon composition, supports runtime add/remove
- Separation of concerns: components handle single responsibilities

**Singleton Pattern**
- `GameManager` autoload controls global state (time, difficulty, stages)
- Prevents tight coupling while providing centralized game state
- Signal-driven communication for stage transitions and difficulty updates

**Resource Registry Pattern**
- `WeaponRegistry` resource maps weapon names → scripts
- Supports runtime registration and lookup
- Editor-friendly with @export properties

**Signal-Driven Architecture**
- UI Coordinator pattern: Player → game.gd → UI (prevents circular dependencies)
- Loose coupling between systems (player, enemies, weapons, UI)
- Example flow: `player.level_up → game.gd._on_level_up → level_up_menu.show_menu()`

**Factory Pattern (via Object Pools)**
- Pools act as factories with instance recycling
- `EnemyPool` and `ProjectilePool` handle creation and lifecycle
- Configurable via exported scene properties

---

## Key Systems

### 1. Object Pool Implementation
```gdscript
# EnemyPool.gd
class_name EnemyPool extends Node

var pool: Array[Node] = []
var active_instances: Array[Node] = []

func get_enemy() -> Node:
    var enemy: Node = null

    # Reuse inactive instance
    if pool.size() > 0:
        enemy = pool.pop_back()
    # Create new if under max
    elif get_child_count() < max_pool_size:
        enemy = _create_new_instance()

    active_instances.append(enemy)
    return enemy

func return_to_pool(enemy: Node) -> void:
    active_instances.erase(enemy)
    pool.append(enemy)
    enemy.reset_state()  # Reset all properties
```

### 2. Weapon System
- **Base Class Inheritance** - `WeaponBase` provides auto-targeting and firing logic
- **10 Unique Weapons** - Projectile, melee, continuous damage, homing, area effects
- **Per-Weapon Upgrades** - 18 stat types (damage, fire rate, pierce, multi-shot, etc.)
- **Computed Properties** - Stats use getters for real-time multiplier application
  ```gdscript
  var damage: float:
      get: return base_damage * damage_multiplier
  ```
- **Smart Melee Detection** - Speed-reactive range prevents fast enemies from feeling unfair
  ```gdscript
  detection_range = base_range * 1.3 + (enemy_speed * 0.6)
  ```

### 3. Enemy AI & Spawning
- **Polymorphic Enemy Base** - `EnemyBase` provides chase AI, inherited by 4 enemy types
- **Difficulty-Scaled Stats** - Health, speed, and spawn rate scale with time
- **Spawn Distribution** - Circular spawn area at 600px from player, avoids camera view
- **Enemy Variety** - Base zombie, fast zombie cat (time-window spawning), tank (big zombie), boss

### 4. Progression System
- **Exponential XP Curve** - `base_xp * 1.2^level` for smooth scaling
- **Dynamic Upgrade Pool** - 3 random upgrades per level-up, specific to active weapons
- **Multi-Stage System** - 5-minute stages with exponential difficulty multipliers (2^stage)
- **Boss Encounters** - Stage completion triggers boss spawn with special mechanics

### 5. Chunk Management
```gdscript
# ChunkManager.gd
func _update_chunks() -> void:
    var player_chunk: Vector2i = _world_to_chunk(player.global_position)

    # Load chunks in radius
    for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
        for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
            var chunk_pos := Vector2i(x, y) + player_chunk
            if chunk_pos not in _loaded_chunks:
                _load_chunk(chunk_pos)

    # Unload distant chunks (hysteresis prevents thrashing)
    for chunk_pos in _loaded_chunks.keys():
        if chunk_pos.distance_to(player_chunk) > UNLOAD_RADIUS:
            _unload_chunk(chunk_pos)
```

---

## Code Quality Features

- **100% Type Hints** - All variables, function parameters, and return types explicitly typed
- **Comprehensive Documentation** - Docstrings on all classes and complex functions
- **Constants Centralization** - `GameConstants` eliminates magic numbers
- **Safe Node Operations** - `NodeUtils` utility class prevents crashes from freed nodes
- **GDScript Style Guide Adherence** - Consistent naming (snake_case, PascalCase, UPPER_SNAKE_CASE)
- **Signal-First Design** - Minimal direct references, maximum decoupling

---

## Project Structure

```
scripts/
├── autoload/          # Singleton systems (GameManager)
├── components/        # Reusable components (HealthComponent, WeaponManager)
├── constants/         # Configuration constants
├── utilities/         # Helper functions (NodeUtils)
├── weapons/           # 10 weapon implementations
├── enemies/           # 4 enemy types
├── ui/                # 5 UI screens (HUD, menus)
└── pickups/           # Collectibles (XP shards)

scenes/
├── game.tscn          # Main scene
├── characters/        # Player scene
├── enemies/           # Enemy scenes
├── weapons/           # Projectile/hitbox scenes
└── ui/                # UI scenes
```

---

## Running the Game

**Requirements:** Godot 4.5+

```bash
# Clone repository
git clone <repo-url>

# Open in Godot
godot --path wasteland-survivors

# Or run directly
godot --path wasteland-survivors res://scenes/game.tscn
```

**Controls:**
- WASD / Arrow Keys: Move
- ESC: Pause
- Weapons auto-fire at nearest enemies

---

## What This Demonstrates

### Programming Competencies
- **Performance Engineering** - Object pooling, chunk management, deferred operations
- **Software Architecture** - Components, singletons, factories, signals
- **Systems Design** - Exponential scaling with caps, upgrade trees, progression curves
- **Code Quality** - Type safety, documentation, constants, utilities
- **Problem Solving** - Speed-reactive melee, pool pre-warming, hysteresis in chunk loading
- **Game Systems** - AI, procedural generation, state machines, difficulty balancing

### Godot-Specific Skills
- Advanced node architecture (components as children)
- Signal-driven communication patterns
- Resource-based configuration
- Autoload singleton management
- Physics optimization (move_and_slide, Area2D, collision layers)
- Animation system integration

### Software Engineering Practices
- Clean separation of concerns
- DRY principles (reusable components)
- SOLID principles (single responsibility, open/closed)
- Defensive programming (null checks, validity checks)
- Performance profiling and optimization

---

## Implementation Stats

- **10 Weapons** with unique mechanics
- **4 Enemy Types** with scaling AI
- **15 Playable Characters** with unique starting loadouts
- **18 Upgrade Stats** across weapons
- **5 UI Screens** (HUD, pause, level-up, game over, stage complete)
- **~3,500 lines of code** (excluding engine files)
- **100% type coverage** on all GDScript

---

## Technical Challenges Solved

1. **GC Pressure from Spawning** → Object pooling with pre-warming
2. **Infinite World Performance** → Chunk-based loading with hysteresis
3. **Exponential Difficulty Balancing** → Cap spawn/speed, scale health infinitely
4. **Fast Enemies Feeling Unfair** → Speed-reactive melee detection range
5. **Weapon Upgrade Flexibility** → Per-weapon stat configuration with computed properties
6. **UI-Gameplay Coupling** → Coordinator pattern with signal routing

---

## Future Enhancements

- Meta-progression system (unlock characters/weapons between runs)
- Save/load system for high scores and unlocks
- Particle effects and screen shake (game feel polish)
- Audio system (SFX and music)
- More weapon synergies and combinations

---

**Part of [2D Game Projects](../) portfolio repository**
