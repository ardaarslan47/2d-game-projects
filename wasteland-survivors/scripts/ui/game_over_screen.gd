class_name GameOverScreen
extends CanvasLayer

## Game over screen that displays final stats and allows restart or quit.

# Onready variables
@onready var time_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var level_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/LevelLabel

# Public methods
func show_game_over(time_survived: String, level: int) -> void:
	"""Display the game over screen with final stats."""
	time_label.text = "Time Survived: %s" % time_survived
	level_label.text = "Level Reached: %d" % level
	visible = true

# Button signal handlers
func _on_restart_button_pressed() -> void:
	"""Restart the game by returning to character selection."""
	# Unpause the game before changing scenes
	get_tree().paused = false
	# Return to character selection
	get_tree().change_scene_to_file("res://scenes/ui/character_selection.tscn")

func _on_quit_button_pressed() -> void:
	"""Quit the game."""
	get_tree().quit()
