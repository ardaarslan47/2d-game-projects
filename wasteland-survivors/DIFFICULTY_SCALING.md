# Difficulty Scaling System

## Overview
Time-based difficulty scaling system that makes enemies progressively harder as the game continues.

## How It Works

### Health Scaling
Enemies start with **10 HP** and gain **+5 HP per minute**:
- **0:00** - 10 HP (1-shot kill with pistol doing 10 damage)
- **1:00** - 15 HP (2 shots)
- **2:00** - 20 HP (2 shots)
- **3:00** - 25 HP (3 shots)
- **5:00** - 35 HP (4 shots)
- **10:00** - 60 HP (6 shots)
- **20:00** - 110 HP (11 shots)
- **38:00+** - 200 HP (capped at maximum)

### Formula
```
enemy_health = BASE_HEALTH + (minutes_elapsed × HEALTH_PER_MINUTE)
enemy_health = min(enemy_health, MAX_HEALTH)
```

### Configuration
All values are in `scripts/constants/game_constants.gd`:

```gdscript
const BASE_ENEMY_HEALTH: int = 10      # Starting health
const HEALTH_PER_MINUTE: int = 5       # Health increase per minute
const MAX_ENEMY_HEALTH: int = 200      # Maximum cap
const DIFFICULTY_INTERVAL: float = 60.0 # Difficulty level every 60s
```

## Architecture

### GameManager (Autoload Singleton)
**Location**: `scripts/autoload/game_manager.gd`

**Responsibilities**:
- Track elapsed game time
- Calculate difficulty level
- Provide scaled enemy stats
- Emit signals for difficulty changes

**Key Methods**:
```gdscript
GameManager.start_game()                    # Start tracking time
GameManager.stop_game()                     # Stop tracking
GameManager.get_scaled_enemy_health()       # Get current enemy health
GameManager.get_spawn_rate_multiplier()     # Future: faster spawns
GameManager.get_difficulty_stats()          # Get all stats for UI
GameManager.get_formatted_time()            # Get "MM:SS" string
```

**Signals**:
```gdscript
signal game_time_changed(elapsed_seconds: float)
signal difficulty_level_changed(level: int)
```

### EnemySpawner Integration
**Location**: `scripts/enemy_spawner.gd`

- Calls `GameManager.start_game()` in `_ready()`
- After spawning each enemy, calls `_apply_difficulty_scaling(enemy)`
- Sets enemy's HealthComponent max_health and current_health to scaled value

## Usage Examples

### Getting Current Difficulty Stats
```gdscript
var stats = GameManager.get_difficulty_stats()
print("Time: ", stats.time)
print("Level: ", stats.difficulty_level)
print("Enemy Health: ", stats.enemy_health)
print("Spawn Rate: ", stats.spawn_multiplier)
```

### Displaying Game Time in UI
```gdscript
# In HUD or UI script
func _process(_delta: float) -> void:
    time_label.text = GameManager.get_formatted_time()
    # Shows: "03:45" for 3 minutes 45 seconds
```

### Listening for Difficulty Changes
```gdscript
func _ready() -> void:
    GameManager.difficulty_level_changed.connect(_on_difficulty_increased)

func _on_difficulty_increased(level: int) -> void:
    print("Difficulty increased to level ", level)
    # Show message to player, play sound, etc.
```

## Tuning Guide

Want to adjust difficulty? Edit `game_constants.gd`:

### Make Game Easier
```gdscript
const BASE_ENEMY_HEALTH: int = 5       # Start at 5 HP (half health)
const HEALTH_PER_MINUTE: int = 3       # Slower scaling
const MAX_ENEMY_HEALTH: int = 100      # Lower cap
```

### Make Game Harder
```gdscript
const BASE_ENEMY_HEALTH: int = 15      # Start at 15 HP
const HEALTH_PER_MINUTE: int = 10      # Faster scaling
const MAX_ENEMY_HEALTH: int = 500      # Higher cap
```

### Make Early Game Easier, Late Game Harder
```gdscript
const BASE_ENEMY_HEALTH: int = 5       # Easy start
const HEALTH_PER_MINUTE: int = 10      # Rapid scaling
const MAX_ENEMY_HEALTH: int = 300      # High cap
```

## Future Enhancements

### Spawn Rate Scaling (Ready to Implement)
GameManager already has `get_spawn_rate_multiplier()`:
- Returns 1.0 at start
- +10% per difficulty level
- Can be used in EnemySpawner to spawn faster

```gdscript
# In enemy_spawner.gd _process()
var base_interval = 1.0
var scaled_interval = base_interval / GameManager.get_spawn_rate_multiplier()
_spawn_timer = scaled_interval
```

### Enemy Damage Scaling
```gdscript
# In GameManager
func get_scaled_enemy_damage(base_damage: int = 10) -> int:
    var minutes_elapsed = game_time / 60.0
    return base_damage + int(minutes_elapsed * 2)  # +2 damage per minute
```

### Movement Speed Scaling
```gdscript
# In GameManager
func get_scaled_movement_speed(base_speed: float = 80.0) -> float:
    var speed_multiplier = 1.0 + (current_difficulty_level * 0.05)
    return base_speed * speed_multiplier  # +5% per level
```

### Different Enemy Types with Different Scaling
```gdscript
# In EnemySpawner
func _apply_difficulty_scaling(enemy: EnemyBase) -> void:
    var base_health = 10

    # Boss enemies have higher base health
    if enemy is BossEnemy:
        base_health = 50

    var scaled_health = GameManager.get_scaled_enemy_health(base_health)
    enemy.health_component.set_max_health(scaled_health)
```

## Testing

### Quick Test Different Times
```gdscript
# In game scene or debug console
GameManager.game_time = 300.0  # Jump to 5 minutes
print("Enemy health at 5min: ", GameManager.get_scaled_enemy_health())
# Output: 35 HP
```

### Reset Game
```gdscript
GameManager.stop_game()
GameManager.start_game()
# Resets time to 0, difficulty to level 0
```

## Files Modified/Created

### New Files
1. `scripts/autoload/game_manager.gd` - Singleton managing game state
2. `DIFFICULTY_SCALING.md` - This documentation

### Modified Files
1. `project.godot` - Added GameManager autoload
2. `scripts/enemy_spawner.gd` - Applies scaling to spawned enemies
3. `scripts/constants/game_constants.gd` - Added difficulty constants
4. `scenes/enemies/zombie.tscn` - Set base health to 10

## Benefits

✅ **Smooth difficulty curve** - Gradual increase keeps game challenging
✅ **Player skill growth** - Players improve as difficulty increases
✅ **Endless gameplay** - Game can continue indefinitely with cap
✅ **Easy to tune** - All values in one constants file
✅ **Extensible** - Easy to add spawn rate, damage, speed scaling
✅ **UI-friendly** - Provides formatted time and stats for display

## Summary

Your game now has dynamic difficulty! Enemies start at 10 HP (1-shot) and gain +5 HP per minute up to a cap of 200 HP. This creates a satisfying progression where early game is easy (learning phase) and late game is challenging (skill test).

The system is ready to expand with spawn rate increases, damage scaling, and more!
