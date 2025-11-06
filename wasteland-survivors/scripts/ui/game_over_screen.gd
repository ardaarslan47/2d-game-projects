class_name GameOverScreen
extends CanvasLayer

## Game over screen that displays final stats and allows restart or quit.

# Onready variables
@onready var time_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var kills_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/KillsLabel
@onready var level_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/LevelLabel

# Public methods
func show_game_over(time_survived: String, kills: int, level: int) -> void:
	"""Display the game over screen with final stats."""
	time_label.text = "Time Survived: %s" % time_survived
	kills_label.text = "Enemies Killed: %d" % kills
	level_label.text = "Level Reached: %d" % level
	visible = true

# Button signal handlers
func _on_restart_button_pressed() -> void:
	"""Restart the game by reloading the current scene."""
	# Unpause the game before reloading
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	"""Quit the game."""
	get_tree().quit()
