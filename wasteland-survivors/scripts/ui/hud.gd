class_name HUD
extends CanvasLayer

## Simple HUD displaying health bar, timer, and kill count.

# Onready variables
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthBar/HealthLabel
@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerLabel
@onready var level_label: Label = $MarginContainer/VBoxContainer/LevelLabel
@onready var stage_label: Label = $MarginContainer/VBoxContainer/StageLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/XPBar
@onready var xp_label: Label = $MarginContainer/VBoxContainer/XPBar/XPLabel
@onready var boss_health_container: VBoxContainer = $BossHealthContainer
@onready var boss_health_bar: ProgressBar = $BossHealthContainer/BossHealthBar
@onready var boss_health_label: Label = $BossHealthContainer/BossHealthBar/BossHealthLabel
@onready var boss_name_label: Label = $BossHealthContainer/BossNameLabel

# Private variables
var _game_time: float = 0.0
var _current_boss: EnemyBase = null

func _ready() -> void:
	# Connect to player
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.xp_changed.connect(_on_player_xp_changed)
		player.level_up.connect(_on_player_level_up)

	# Update initial stage
	_update_stage()

	# Hide boss health bar initially
	if boss_health_container:
		boss_health_container.visible = false

func _process(delta: float) -> void:
	# Use GameManager time instead of local timer
	_game_time = GameManager.game_time
	_update_timer()
	_update_stage()
	_update_boss_health_bar()

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

func _update_stage() -> void:
	stage_label.text = "Stage: %d" % GameManager.current_stage

func _on_player_xp_changed(current_xp: int, xp_to_next_level: int) -> void:
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = current_xp
	xp_label.text = "%d / %d" % [current_xp, xp_to_next_level]

func _on_player_level_up(new_level: int) -> void:
	level_label.text = "Level: %d" % new_level

func _update_boss_health_bar() -> void:
	"""Update boss health bar if boss is active."""
	if not boss_health_container:
		return

	# Find boss in the scene
	var bosses: Array[Node] = get_tree().get_nodes_in_group("boss")

	if bosses.size() > 0:
		# Boss is alive - show health bar
		_current_boss = bosses[0] as EnemyBase
		if _current_boss and _current_boss.health_component:
			boss_health_container.visible = true

			# Update health bar values
			var current_health: int = _current_boss.health_component.current_health
			var max_health: int = _current_boss.health_component.max_health

			boss_health_bar.max_value = max_health
			boss_health_bar.value = current_health
			boss_health_label.text = "%d / %d" % [current_health, max_health]
			boss_name_label.text = "BOSS"

			# Color boss health bar (always red/orange for menacing look)
			boss_health_bar.modulate = Color(1.0, 0.3, 0.0)  # Orange-red
	else:
		# No boss - hide health bar
		boss_health_container.visible = false
		_current_boss = null
