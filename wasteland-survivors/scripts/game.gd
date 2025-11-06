extends Node2D

## Main game controller script.
## Manages connections between player, UI, and game systems.

# Onready variables
@onready var player: Player = $Player
@onready var level_up_menu: LevelUpMenu = $LevelUpMenu

func _ready() -> void:
	# Start the game session
	GameManager.start_game()

	# Connect player signals to UI
	if player and level_up_menu:
		player.level_up.connect(_on_player_level_up)
		level_up_menu.upgrade_selected.connect(_on_upgrade_selected)

func _on_player_level_up(new_level: int) -> void:
	"""Show level-up menu when player levels up."""
	level_up_menu.show_menu()

func _on_upgrade_selected(upgrade_data: Dictionary) -> void:
	"""Apply the selected upgrade to the player."""
	player.apply_upgrade(upgrade_data)
