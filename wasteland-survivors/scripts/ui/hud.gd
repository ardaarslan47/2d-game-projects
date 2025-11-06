class_name HUD
extends CanvasLayer

## Simple HUD displaying health bar, timer, and kill count.

# Onready variables
@onready var health_bar: ProgressBar = $MarginContainer/BackgroundPanel/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/BackgroundPanel/VBoxContainer/HealthBar/HealthLabel
@onready var timer_label: Label = $MarginContainer/BackgroundPanel/VBoxContainer/TimerLabel
@onready var kill_label: Label = $MarginContainer/BackgroundPanel/VBoxContainer/KillLabel
@onready var level_label: Label = $MarginContainer/BackgroundPanel/VBoxContainer/LevelLabel
@onready var stage_label: Label = $MarginContainer/BackgroundPanel/VBoxContainer/StageLabel
@onready var xp_bar: ProgressBar = $MarginContainer/BackgroundPanel/VBoxContainer/XPBar
@onready var xp_label: Label = $MarginContainer/BackgroundPanel/VBoxContainer/XPBar/XPLabel

# Private variables
var _game_time: float = 0.0
var _kill_count: int = 0

func _ready() -> void:
	# Connect to player
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.xp_changed.connect(_on_player_xp_changed)
		player.level_up.connect(_on_player_level_up)

	# Connect to enemies
	get_tree().node_added.connect(_on_node_added)

	# Update initial stage
	_update_stage()

func _process(delta: float) -> void:
	_game_time += delta
	_update_timer()
	_update_stage()

# Public methods
func increment_kills() -> void:
	_kill_count += 1
	_update_kills()

# Private methods
func _on_player_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [current, maximum]

	# Update health bar color based on percentage
	var health_percent: float = float(current) / float(maximum)
	if health_percent > 0.6:
		# Green when healthy (> 60%)
		health_bar.modulate = Color(0.2, 1.0, 0.2)  # Bright green
	elif health_percent > 0.3:
		# Yellow when hurt (30-60%)
		health_bar.modulate = Color(1.0, 1.0, 0.0)  # Yellow
	else:
		# Red when critical (< 30%)
		health_bar.modulate = Color(1.0, 0.2, 0.2)  # Bright red

func _update_timer() -> void:
	var minutes: int = int(_game_time) / 60
	var seconds: int = int(_game_time) % 60
	timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

func _update_kills() -> void:
	kill_label.text = "Kills: %d" % _kill_count

func _update_stage() -> void:
	stage_label.text = "Stage: %d" % GameManager.current_stage

func _on_player_xp_changed(current_xp: int, xp_to_next_level: int) -> void:
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
	xp_label.text = "%d / %d" % [current_xp, xp_to_next_level]

func _on_player_level_up(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level

func _on_node_added(node: Node) -> void:
	if node.is_in_group("enemies"):
		if node.has_signal("died"):
			node.died.connect(increment_kills)
