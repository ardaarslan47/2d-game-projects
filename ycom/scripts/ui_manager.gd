extends CanvasLayer

## UI Manager for turn-based gameplay.
## Displays AP, turn info, health bars, and provides End Turn button.

# Node references
@onready var ap_label: Label = $UI/APLabel
@onready var turn_label: Label = $UI/TurnLabel
@onready var end_turn_button: Button = $UI/EndTurnButton
@onready var player_health_bar: ProgressBar = $UI/PlayerHealthBar
@onready var player_health_label: Label = $UI/PlayerHealthLabel

# Action buttons (like LoL skills)
@onready var move_button: Button = $UI/ActionButtons/MoveButton
@onready var attack_button: Button = $UI/ActionButtons/AttackButton
@onready var wait_button: Button = $UI/ActionButtons/WaitButton

var player: Player = null
var turn_manager: Node = null
var enemies: Array[Enemy] = []
var current_selected_action: String = ""  # "move", "attack", or ""


func _ready() -> void:
	# Wait for scene to be ready
	await get_tree().process_frame

	# Find references
	player = get_tree().get_first_node_in_group("player")
	turn_manager = get_node("../TurnManager")

	# Enable input processing for keyboard shortcuts
	set_process_input(true)

	if player:
		# Connect to player AP and health changes
		player.action_points_changed.connect(_on_player_ap_changed)
		player.health_changed.connect(_on_player_health_changed)
		_update_ap_display()
		_update_player_health_display()

	if turn_manager:
		# Connect to turn changes
		turn_manager.actor_turn_started.connect(_on_actor_turn_started)
		turn_manager.round_completed.connect(_on_round_completed)

	# Connect buttons
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	if move_button:
		move_button.pressed.connect(_on_move_button_pressed)
		move_button.toggle_mode = true

	if attack_button:
		attack_button.pressed.connect(_on_attack_button_pressed)
		attack_button.toggle_mode = true

	if wait_button:
		wait_button.pressed.connect(_on_wait_button_pressed)

	# Connect to game state
	GameState.state_changed.connect(_on_game_state_changed)

	_update_displays()


func _input(event: InputEvent) -> void:
	# Handle keyboard shortcuts for action buttons
	if event is InputEventKey and event.pressed and not event.echo:
		# Only allow shortcuts during player turn
		if not GameState.can_player_act():
			return

		match event.keycode:
			KEY_Q:
				# Toggle Move button
				if move_button:
					move_button.button_pressed = not move_button.button_pressed
					_on_move_button_pressed()
			KEY_W:
				# Toggle Attack button
				if attack_button:
					attack_button.button_pressed = not attack_button.button_pressed
					_on_attack_button_pressed()
			KEY_E:
				# Press Wait button
				if wait_button:
					_on_wait_button_pressed()


func _update_ap_display() -> void:
	if player and ap_label:
		ap_label.text = "AP: %d/%d" % [player.get_action_points(), player.get_max_action_points()]


func _update_player_health_display() -> void:
	if not player:
		return

	if player_health_bar:
		player_health_bar.max_value = player.max_health
		player_health_bar.value = player.current_health

	if player_health_label:
		player_health_label.text = "HP: %d/%d" % [player.current_health, player.max_health]


func _update_turn_display(actor: Node) -> void:
	if turn_label:
		if actor == player:
			turn_label.text = "YOUR TURN"
		else:
			turn_label.text = "ENEMY TURN"


func _update_displays() -> void:
	_update_ap_display()
	_update_player_health_display()

	if turn_manager and turn_label:
		var current_actor: Node = turn_manager.get_current_actor()
		if current_actor:
			_update_turn_display(current_actor)


## Select an action button (radio button behavior).
func select_action(action: String) -> void:
	current_selected_action = action

	# Update button states (only one pressed at a time)
	if move_button:
		move_button.button_pressed = (action == "move")
	if attack_button:
		attack_button.button_pressed = (action == "attack")

	# Notify GameManager (parent node has the GameManager script)
	var game_manager: Node = get_parent()
	if game_manager and game_manager.has_method("set_action_mode"):
		game_manager.set_action_mode(action)


## Deselect all action buttons.
func deselect_all_actions() -> void:
	current_selected_action = ""

	if move_button:
		move_button.button_pressed = false
	if attack_button:
		attack_button.button_pressed = false


# Signal handlers
func _on_player_ap_changed(_current: int, _max: int) -> void:
	_update_ap_display()


func _on_actor_turn_started(actor: Node) -> void:
	_update_turn_display(actor)
	_update_ap_display()

	# Enable/disable end turn button
	if end_turn_button:
		end_turn_button.disabled = (actor != player)


func _on_round_completed(round_num: int) -> void:
	print("UI: Round ", round_num, " completed")


func _on_end_turn_pressed() -> void:
	if turn_manager:
		turn_manager.force_end_turn()


func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	# Disable button during animations
	if end_turn_button:
		if new_state == GameState.GameStates.ANIMATING:
			end_turn_button.disabled = true
		elif new_state == GameState.GameStates.PLAYER_TURN:
			end_turn_button.disabled = false


func _on_player_health_changed(_current: int, _max: int) -> void:
	_update_player_health_display()


func _on_move_button_pressed() -> void:
	print("UI: Move button pressed")
	if move_button and move_button.button_pressed:
		select_action("move")
	else:
		deselect_all_actions()


func _on_attack_button_pressed() -> void:
	print("UI: Attack button pressed")
	if attack_button and attack_button.button_pressed:
		select_action("attack")
	else:
		deselect_all_actions()


func _on_wait_button_pressed() -> void:
	print("UI: Wait button pressed")
	# Wait doesn't need selection, just end turn
	if turn_manager:
		turn_manager.force_end_turn()
	deselect_all_actions()
