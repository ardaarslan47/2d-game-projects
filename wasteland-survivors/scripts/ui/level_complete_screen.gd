class_name LevelCompleteScreen
extends CanvasLayer

## Level complete screen that appears when a stage is completed.
## Shows stats and allows progression to next stage.

# Signals
signal next_level_requested

# Onready variables
@onready var current_stage_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/CurrentStageLabel
@onready var time_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/TimeLabel
@onready var level_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatsContainer/LevelLabel

# Public methods
func show_level_complete(stage: int, time_survived: String, player_level: int) -> void:
	"""Display the level complete screen with stats."""
	current_stage_label.text = "Stage %d Complete" % stage
	time_label.text = "Time: %s" % time_survived
	level_label.text = "Player Level: %d" % player_level
	visible = true

func hide_screen() -> void:
	"""Hide the level complete screen."""
	visible = false

# Button signal handlers
func _on_next_level_button_pressed() -> void:
	"""Progress to the next level."""
	next_level_requested.emit()
	hide_screen()
