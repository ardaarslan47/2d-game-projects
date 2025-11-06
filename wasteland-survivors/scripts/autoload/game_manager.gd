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
var health_per_minute: int = GameConstants.HEALTH_PER_MINUTE
var max_enemy_health: int = GameConstants.MAX_ENEMY_HEALTH
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
func get_scaled_enemy_health(base_health: int = 0) -> int:
	if base_health <= 0:
		base_health = base_enemy_health

	# Calculate health based on minutes elapsed
	var minutes_elapsed: float = game_time / 60.0
	var health_bonus: int = int(minutes_elapsed * health_per_minute)

	var total_health: int = base_health + health_bonus

	# Cap at maximum
	return min(total_health, max_enemy_health)

## Get the current spawn rate multiplier (enemies spawn faster over time).
func get_spawn_rate_multiplier() -> float:
	# Start at 1.0, increase by 10% per difficulty level
	return 1.0 + (current_difficulty_level * 0.1)

## Get current difficulty stats for UI display.
func get_difficulty_stats() -> Dictionary:
	return {
		"time": game_time,
		"difficulty_level": current_difficulty_level,
		"enemy_health": get_scaled_enemy_health(),
		"spawn_multiplier": get_spawn_rate_multiplier()
	}

## Format game time as MM:SS string.
func get_formatted_time() -> String:
	var minutes: int = int(game_time / 60.0)
	var seconds: int = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]
