extends Node

## Turn Manager for XCOM-like tactical combat.
## Manages turn order, actor turns, and coordinates with GameState.

# Signals
signal turn_order_changed(actors: Array[Node])
signal actor_turn_started(actor: Node)
signal actor_turn_ended(actor: Node)
signal round_completed(round_number: int)

# Turn tracking
var current_turn_index: int = 0
var round_number: int = 1

# Actor management
var actors: Array[Node] = []  # All actors that can take turns (player + enemies)
var player: Player = null

# Private state
var _waiting_for_animation: bool = false


func _ready() -> void:
	# Wait for the scene tree to be ready
	await get_tree().process_frame
	await get_tree().process_frame  # Wait an extra frame to ensure all nodes are ready

	# Find and register the player
	player = get_tree().get_first_node_in_group("player")
	if player:
		register_actor(player)
		# Connect to player signals
		player.movement_completed.connect(_on_player_movement_completed)
		player.action_points_depleted.connect(_on_player_action_points_depleted)
		print("TurnManager: Player found and registered")
	else:
		push_warning("TurnManager: Could not find player in 'player' group!")

	# Register initial enemies
	_register_existing_enemies()

	# Start the first turn
	start_first_turn()


## Register all enemies currently in the scene.
## Called initially and when we need to refresh the enemy list.
func _register_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		register_actor(enemy)
		print("TurnManager: Enemy '", enemy.name, "' registered")


## Sync actors list with enemies currently in the "enemies" group.
## Adds new enemies that spawned, removes enemies that were destroyed.
func _sync_enemies_from_group() -> void:
	var enemies_in_group: Array[Node] = get_tree().get_nodes_in_group("enemies")

	# Add new enemies that aren't registered yet
	for enemy in enemies_in_group:
		if enemy not in actors and enemy != player:
			register_actor(enemy)
			print("TurnManager: Dynamically registered new enemy: ", enemy.name)

	# Remove actors that are no longer in the enemies group (died or despawned)
	var actors_to_remove: Array[Node] = []
	for actor in actors:
		if actor == player:
			continue  # Never remove player
		if actor not in enemies_in_group:
			actors_to_remove.append(actor)

	for actor in actors_to_remove:
		unregister_actor(actor)
		print("TurnManager: Removed destroyed/despawned enemy: ", actor.name)


## Register an actor to participate in turns.
func register_actor(actor: Node) -> void:
	if actor not in actors:
		actors.append(actor)
		print("TurnManager: Registered actor: ", actor.name)
		turn_order_changed.emit(actors)


## Unregister an actor (e.g., when defeated).
func unregister_actor(actor: Node) -> void:
	var index: int = actors.find(actor)
	if index != -1:
		actors.remove_at(index)
		print("TurnManager: Unregistered actor: ", actor.name)
		turn_order_changed.emit(actors)

		# Adjust current turn index if needed
		if current_turn_index >= actors.size() and actors.size() > 0:
			current_turn_index = 0


## Start the first turn of the game.
func start_first_turn() -> void:
	if actors.is_empty():
		push_error("TurnManager: No actors registered!")
		return

	round_number = 1
	current_turn_index = 0
	print("TurnManager: Starting game - Round ", round_number)
	_start_actor_turn()


## End the current actor's turn and move to the next.
func end_current_turn() -> void:
	var current_actor: Node = get_current_actor()
	if current_actor:
		print("TurnManager: Ending turn for ", current_actor.name)
		actor_turn_ended.emit(current_actor)

	# Move to next actor
	current_turn_index += 1

	# Check if round is complete
	if current_turn_index >= actors.size():
		_complete_round()
		current_turn_index = 0

	# Start next actor's turn
	_start_actor_turn()


## Get the actor whose turn it currently is.
func get_current_actor() -> Node:
	if current_turn_index < actors.size():
		return actors[current_turn_index]
	return null


## Check if it's the player's turn.
func is_player_turn() -> bool:
	var current_actor: Node = get_current_actor()
	return current_actor == player


## Force end turn (called by player UI button).
func force_end_turn() -> void:
	if not is_player_turn():
		print("TurnManager: Cannot force end turn - not player's turn")
		return

	if _waiting_for_animation:
		print("TurnManager: Cannot end turn while animation is playing")
		return

	print("TurnManager: Player manually ended turn")
	end_current_turn()


# Private methods
func _start_actor_turn() -> void:
	# Sync enemies from group before starting turn
	_sync_enemies_from_group()

	var actor: Node = get_current_actor()
	if not actor:
		push_error("TurnManager: No valid actor for turn!")
		return

	print("TurnManager: Starting turn for ", actor.name, " (Round ", round_number, ")")

	# Reset actor's action points if they have the method
	if actor.has_method("reset_action_points"):
		actor.reset_action_points()

	# Notify that turn has started
	actor_turn_started.emit(actor)
	if is_instance_valid(GameState):
		GameState.start_turn(round_number)

	# If it's an enemy turn, execute AI (placeholder for now)
	if actor != player:
		_execute_enemy_turn(actor)


func _execute_enemy_turn(enemy: Node) -> void:
	# Change to enemy turn state
	if is_instance_valid(GameState):
		GameState.change_state(GameState.GameStates.ENEMY_TURN)

	# Check if enemy has AI component
	var ai: Node = enemy.get_node_or_null("EnemyAI")
	if ai == null or not ai.has_method("execute_turn"):
		print("TurnManager: Enemy ", enemy.name, " has no AI - skipping turn")
		await get_tree().create_timer(0.5).timeout
		end_current_turn()
		return

	print("TurnManager: Enemy ", enemy.name, " taking turn")

	# Execute AI actions until out of AP or can't act
	var can_act: bool = true
	while can_act and enemy.has_method("get_action_points") and enemy.get_action_points() > 0:
		can_act = await ai.execute_turn()

		# Small delay between actions for visibility
		if can_act:
			await get_tree().create_timer(0.3).timeout

	print("TurnManager: Enemy ", enemy.name, " turn complete")
	await get_tree().create_timer(0.5).timeout
	end_current_turn()


func _complete_round() -> void:
	print("TurnManager: Round ", round_number, " completed")
	round_completed.emit(round_number)
	round_number += 1


# Signal handlers
func _on_player_movement_completed() -> void:
	# Movement animation finished, return to player turn state
	if _waiting_for_animation:
		_waiting_for_animation = false
		if is_instance_valid(GameState):
			GameState.finish_animation()


func _on_player_action_points_depleted() -> void:
	print("TurnManager: Player action points depleted")
	# Note: We don't auto-end turn - player can still choose to end turn manually
	# This gives them a chance to review the situation
