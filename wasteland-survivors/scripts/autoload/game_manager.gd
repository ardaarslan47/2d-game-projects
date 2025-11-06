extends Node

## Global game manager - tracks game state, time, and difficulty scaling.
## This is an autoload singleton accessible from anywhere via GameManager.

# Signals
signal game_time_changed(elapsed_seconds: float)
signal difficulty_level_changed(level: int)

# Game time tracking
var game_time: float = 0.0
var is_game_running: bool = false

# Difficulty scaling settings (using GameConstants)
var base_enemy_health: int = GameConstants.BASE_ENEMY_HEALTH
var difficulty_interval: float = GameConstants.DIFFICULTY_INTERVAL

# Current difficulty stats
var current_difficulty_level: int = 0

func _ready() -> void:
	# Don't process in editor
	set_process(false)

func start_game() -> void:
	"""Start a new game session."""
	game_time = 0.0
	current_difficulty_level = 0
	is_game_running = true
	set_process(true)

func stop_game() -> void:
	"""Stop the current game session."""
	is_game_running = false
	set_process(false)

func _process(delta: float) -> void:
	if not is_game_running:
		return

	game_time += delta
	game_time_changed.emit(game_time)

	# Check for difficulty level increase
	var new_difficulty_level: int = int(game_time / difficulty_interval)
	if new_difficulty_level > current_difficulty_level:
		current_difficulty_level = new_difficulty_level
		difficulty_level_changed.emit(current_difficulty_level)

## Get the current enemy health based on elapsed game time.
## Uses exponential power function: base * (1 + time)^exponent
## No cap - health grows exponentially indefinitely.
func get_scaled_enemy_health(base_health: int = 0) -> int:
	if base_health <= 0:
		base_health = base_enemy_health

	# Calculate health using power function: base * (1 + minutes)^exponent
	var minutes_elapsed: float = game_time / 60.0
	var scale_factor: float = pow(1.0 + minutes_elapsed, GameConstants.HEALTH_SCALE_EXPONENT)
	var scaled_health: int = int(base_health * scale_factor)

	return scaled_health

## Get the current spawn rate multiplier (enemies spawn faster over time).
## Uses exponential growth: growth_rate^(time/interval)
## Capped at MAX_SPAWN_RATE_MULTIPLIER for performance.
func get_spawn_rate_multiplier() -> float:
	# Exponential growth: 1.05^(game_time / 30.0) = 5% increase every 30 seconds
	var intervals_passed: float = game_time / GameConstants.SPAWN_RATE_INTERVAL
	var multiplier: float = pow(GameConstants.SPAWN_RATE_GROWTH, intervals_passed)

	# Cap at maximum for performance
	return min(multiplier, GameConstants.MAX_SPAWN_RATE_MULTIPLIER)

## Get the current movement speed multiplier (enemies move faster over time).
## Uses linear stepped growth: +10% every 2 minutes
## Capped at MAX_SPEED_MULTIPLIER to prevent teleporting.
func get_movement_speed_multiplier() -> float:
	# Linear stepped growth: 1.0 + 0.10 * floor(time / 120.0)
	var intervals_passed: int = int(game_time / GameConstants.SPEED_GROWTH_INTERVAL)
	var multiplier: float = 1.0 + (GameConstants.SPEED_GROWTH_PER_INTERVAL * intervals_passed)

	# Cap at maximum to prevent teleporting enemies
	return min(multiplier, GameConstants.MAX_SPEED_MULTIPLIER)

## Get current difficulty stats for UI display.
func get_difficulty_stats() -> Dictionary:
	return {
		"time": game_time,
		"difficulty_level": current_difficulty_level,
		"enemy_health": get_scaled_enemy_health(),
		"spawn_multiplier": get_spawn_rate_multiplier(),
		"speed_multiplier": get_movement_speed_multiplier()
	}

## Format game time as MM:SS string.
func get_formatted_time() -> String:
	var minutes: int = int(game_time / 60.0)
	var seconds: int = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]
