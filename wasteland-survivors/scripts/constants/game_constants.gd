class_name GameConstants

## Central configuration for game-wide constants.
## Reduces magic numbers and makes tuning easier.

# Player Animation
const PLAYER_IDLE_FRAME: int = 3
const PLAYER_DEFAULT_ANIMATION: String = "down"
const PLAYER_VERTICAL_DOMINANCE: float = 1.5  # Vertical movement must be 1.5x stronger to use up/down animation

# Hit Effects - Player
const PLAYER_HIT_FLASH_COLOR: Color = Color(1.0, 0.3, 0.3, 0.5)  # Red and half transparent
const PLAYER_HIT_FLASH_ALPHA_MIN: float = 0.3
const PLAYER_HIT_FLASH_ALPHA_MAX: float = 0.5
const PLAYER_BLINK_RATE: float = 5.0  # Blinks per second during invincibility
const PLAYER_HIT_FLASH_TWEEN_DURATION: float = 0.1

# Hit Effects - Enemy
const ENEMY_HIT_FLASH_COLOR: Color = Color(1.0, 0.5, 0.5)
const ENEMY_HIT_FLASH_DURATION: float = 0.1

# Chunk Management
const CHUNK_UPDATE_INTERVAL: float = 0.5  # Seconds between chunk updates
const CHUNK_SIZE: int = 16  # Tiles per chunk (16x16)
const CHUNK_TILE_SIZE: int = 16  # Pixels per tile
const CHUNK_LOAD_RADIUS: int = 2  # Load chunks within this radius
const CHUNK_UNLOAD_RADIUS: int = 3  # Unload chunks beyond this radius

# Prop Spawning
const PROP_SPAWN_INTERVAL: float = 0.1
const PROP_SPAWN_DENSITY: float = 0.05  # 5% chance per tile
const PROP_MIN_NOISE_VALUE: float = 0.4  # Only spawn props above this noise threshold

# Difficulty Scaling
const BASE_ENEMY_HEALTH: int = 10  # Starting health at game start
const DIFFICULTY_INTERVAL: float = 60.0  # Seconds between difficulty level increases

# Exponential Health Scaling (power function: base * (1 + time)^exponent)
const HEALTH_SCALE_EXPONENT: float = 1.5  # Power function exponent for exponential growth

# Spawn Rate Scaling (exponential: base * growth^(time/interval))
const SPAWN_RATE_GROWTH: float = 1.05  # 5% increase per interval
const SPAWN_RATE_INTERVAL: float = 30.0  # Apply growth every 30 seconds
const MAX_SPAWN_RATE_MULTIPLIER: float = 5.0  # Cap at 5x spawn rate for performance

# Movement Speed Scaling (linear steps: base * (1 + growth * intervals_passed))
const SPEED_GROWTH_INTERVAL: float = 120.0  # Apply growth every 2 minutes (120 seconds)
const SPEED_GROWTH_PER_INTERVAL: float = 0.10  # 10% increase per interval
const MAX_SPEED_MULTIPLIER: float = 2.0  # Cap at 2x speed to prevent teleporting
