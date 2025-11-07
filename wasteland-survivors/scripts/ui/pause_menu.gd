class_name PauseMenu
extends CanvasLayer

## Pause menu that can be toggled with the escape key.
## Pauses the game tree when shown.

func _ready() -> void:
	# Hide by default
	visible = false

func _input(event: InputEvent) -> void:
	# Toggle pause with escape key
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause() -> void:
	"""Toggle between paused and unpaused state."""
	if visible:
		_resume()
	else:
		_pause()

func _pause() -> void:
	"""Show pause menu and pause game."""
	visible = true
	get_tree().paused = true

func _resume() -> void:
	"""Hide pause menu and resume game."""
	visible = false
	get_tree().paused = false

# Button signal handlers
func _on_resume_button_pressed() -> void:
	"""Resume the game."""
	_resume()

func _on_quit_button_pressed() -> void:
	"""Return to character selection menu."""
	# Unpause before changing scenes
	get_tree().paused = false
	# Return to character selection
	get_tree().change_scene_to_file("res://scenes/ui/character_selection.tscn")
