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

func _on_player_level_up(new_level: int) -> void:
	"""Show level-up menu when player levels up."""
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
	var kills: int = hud._kill_count if hud else 0
	var level: int = player.current_level if player else 1

	# Show game over screen with stats
	game_over_screen.show_game_over(time_survived, kills, level)

func _on_stage_completed(stage: int) -> void:
	"""Handle stage completion - pause game and show level complete screen."""
	# Pause the game tree
	get_tree().paused = true

	# Gather stats
	var time_survived: String = GameManager.get_formatted_time()
	var kills: int = hud._kill_count if hud else 0
	var player_level: int = player.current_level if player else 1

	# Show level complete screen
	level_complete_screen.show_level_complete(stage, time_survived, kills, player_level)

func _on_next_level_requested() -> void:
	"""Handle next level button press - clear enemies and start next stage."""
	# Clear all existing enemies
	_clear_all_enemies()

	# Start next stage in GameManager
	GameManager.start_next_stage()

	# Unpause the game
	get_tree().paused = false

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
