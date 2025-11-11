extends Node

## Global game state manager for turn-based gameplay.
## Manages game states, turn progression, and coordinates between systems.
## Accessible via autoload as "GameState"

# Signals
signal state_changed(new_state: GameStates, old_state: GameStates)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal player_turn_started
signal enemy_turn_started
signal animation_started
signal animation_ended

# Enums
enum GameStates {
	PLAYER_TURN,    ## Player can input actions
	ANIMATING,      ## Action animation in progress (blocks input)
	ENEMY_TURN,     ## Enemies are taking their turns
	GAME_OVER       ## Game has ended
}

# State tracking
var current_state: GameStates = GameStates.PLAYER_TURN
var turn_number: int = 1

# Private state
var _previous_state: GameStates = GameStates.PLAYER_TURN


func _ready() -> void:
	# Start the game in player turn state
	change_state(GameStates.PLAYER_TURN)


## Change the current game state and emit relevant signals
func change_state(new_state: GameStates) -> void:
	if current_state == new_state:
		return

	_previous_state = current_state
	current_state = new_state

	# Emit general state change signal
	state_changed.emit(new_state, _previous_state)

	# Emit specific state signals
	match new_state:
		GameStates.PLAYER_TURN:
			player_turn_started.emit()
		GameStates.ENEMY_TURN:
			enemy_turn_started.emit()
		GameStates.ANIMATING:
			animation_started.emit()
		GameStates.GAME_OVER:
			pass  # Handle game over later


## Check if the current state allows player input
func can_player_act() -> bool:
	return current_state == GameStates.PLAYER_TURN


## Check if animations are currently playing
func is_animating() -> bool:
	return current_state == GameStates.ANIMATING


## Start a new turn (called by TurnManager)
func start_turn(turn_num: int) -> void:
	turn_number = turn_num
	turn_started.emit(turn_number)
	change_state(GameStates.PLAYER_TURN)


## End the current turn (called by TurnManager or player input)
func end_turn() -> void:
	turn_ended.emit(turn_number)


## Transition from animating back to the previous turn state
func finish_animation() -> void:
	if current_state == GameStates.ANIMATING:
		# Return to the state we were in before animating
		if _previous_state == GameStates.PLAYER_TURN:
			change_state(GameStates.PLAYER_TURN)
		elif _previous_state == GameStates.ENEMY_TURN:
			change_state(GameStates.ENEMY_TURN)

		animation_ended.emit()


## Get the current state as a readable string (useful for debugging)
func get_state_name() -> String:
	match current_state:
		GameStates.PLAYER_TURN:
			return "PLAYER_TURN"
		GameStates.ANIMATING:
			return "ANIMATING"
		GameStates.ENEMY_TURN:
			return "ENEMY_TURN"
		GameStates.GAME_OVER:
			return "GAME_OVER"
		_:
			return "UNKNOWN"
