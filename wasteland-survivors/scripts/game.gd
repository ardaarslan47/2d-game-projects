extends Node2D

## Main game controller script.
## Manages connections between player, UI, and game systems.

# Onready variables
@onready var player: Player = $Player
@onready var level_up_menu: LevelUpMenu = $LevelUpMenu
@onready var game_over_screen: GameOverScreen = $GameOverScreen
@onready var level_complete_screen: LevelCompleteScreen = $LevelCompleteScreen
@onready var hud: HUD = $HUD
@onready var enemy_spawner: Node2D = $EnemySpawner

# Private variables
var _suppress_level_up_menu: bool = false

func _ready() -> void:
	# Start the game session
	GameManager.start_game()

	# Connect player signals to UI
	if player and level_up_menu:
		player.level_up.connect(_on_player_level_up)
		player.died.connect(_on_player_died)
		level_up_menu.upgrade_selected.connect(_on_upgrade_selected)

	# Connect GameManager stage completion signal
	GameManager.stage_completed.connect(_on_stage_completed)

	# Connect level complete screen signal
	if level_complete_screen:
		level_complete_screen.next_level_requested.connect(_on_next_level_requested)

	# Add to "game_controller" group so boss can signal us
	add_to_group("game_controller")

func _on_player_level_up(new_level: int) -> void:
	"""Show level-up menu when player levels up."""
	# Suppress level up menu during boss defeat XP collection
	if not _suppress_level_up_menu:
		level_up_menu.show_menu()

func _on_upgrade_selected(upgrade_data: Dictionary) -> void:
	"""Apply the selected upgrade to the player."""
	player.apply_upgrade(upgrade_data)

func _on_player_died() -> void:
	"""Handle player death - pause game and show game over screen."""
	# Stop game manager
	GameManager.stop_game()

	# Pause the game tree
	get_tree().paused = true

	# Gather final stats
	var time_survived: String = GameManager.get_formatted_time()
	var level: int = player.current_level if player else 1

	# Show game over screen with stats
	game_over_screen.show_game_over(time_survived, level)

func _on_stage_completed(stage: int) -> void:
	"""Handle stage completion - pause game and show level complete screen."""
	# Pause the game tree
	get_tree().paused = true

	# Gather stats
	var time_survived: String = GameManager.get_formatted_time()
	var player_level: int = player.current_level if player else 1

	# Show level complete screen
	level_complete_screen.show_level_complete(stage, time_survived, player_level)

func _on_next_level_requested() -> void:
	"""Handle next level button press - clear enemies and start next stage."""
	# Clear all existing enemies
	_clear_all_enemies()

	# Reset enemy spawner for new stage
	if enemy_spawner and enemy_spawner.has_method("reset_for_new_stage"):
		enemy_spawner.reset_for_new_stage()

	# Start next stage in GameManager
	GameManager.start_next_stage()

	# Unpause the game
	get_tree().paused = false

func _on_boss_defeated() -> void:
	"""Handle boss defeat - make XP fly to player and wait for collection."""
	print("Boss defeated! Making XP fly to player...")

	# Suppress level up menu during XP collection
	_suppress_level_up_menu = true

	# Make all XP shards fly to player
	var xp_shards: Array[Node] = get_tree().get_nodes_in_group("xp_shards")
	for shard in xp_shards:
		if shard and is_instance_valid(shard) and shard.has_method("fly_to_player"):
			shard.fly_to_player()

	# Wait for all XP shards to be collected
	await _wait_for_all_xp_collected()

	# Re-enable level up menu
	_suppress_level_up_menu = false

	# Trigger stage completion after all XP collected
	_on_stage_completed(GameManager.current_stage)

func _wait_for_all_xp_collected() -> void:
	"""Wait until all XP shards are collected."""
	while true:
		var xp_shards: Array[Node] = get_tree().get_nodes_in_group("xp_shards")
		if xp_shards.size() == 0:
			break
		await get_tree().create_timer(0.1).timeout

func _clear_all_enemies() -> void:
	"""Remove all enemies from the scene."""
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			# Return to pool if possible, otherwise free
			if enemy.has_method("_return_to_pool"):
				enemy._return_to_pool()
			else:
				enemy.queue_free()
