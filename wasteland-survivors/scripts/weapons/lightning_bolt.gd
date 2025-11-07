class_name LightningBolt
extends Node2D

## Lightning bolt visual effect that chains between enemies

# Exported properties
@export var damage: float = 15.0
@export var chain_positions: Array[Vector2] = []
@export var bolt_width: float = 3.0
@export var display_duration: float = 0.15

@onready var bolt_line: Line2D = $BoltLine
@onready var sparks: CPUParticles2D = $Sparks
@onready var lifetime_timer: Timer = $LifetimeTimer


func _ready() -> void:
	bolt_line.width = bolt_width
	lifetime_timer.wait_time = display_duration
	_generate_jagged_bolt()
	_emit_sparks_at_hits()


func _generate_jagged_bolt() -> void:
	if chain_positions.size() < 2:
		return

	var points: PackedVector2Array = []

	# Generate jagged lines between each chain position
	for i in range(chain_positions.size() - 1):
		var start := to_local(chain_positions[i])
		var end := to_local(chain_positions[i + 1])

		# Add jagged segments
		var segment_points := _create_jagged_line(start, end, 8, 10.0)
		for point in segment_points:
			points.append(point)

	bolt_line.points = points


func _create_jagged_line(start: Vector2, end: Vector2, segments: int, jag_amount: float) -> PackedVector2Array:
	var points: PackedVector2Array = [start]

	for i in range(1, segments):
		var t := float(i) / segments
		var linear_point := start.lerp(end, t)

		# Add random perpendicular offset
		var direction := (end - start).normalized()
		var perpendicular := Vector2(-direction.y, direction.x)
		var offset := perpendicular * randf_range(-jag_amount, jag_amount)

		points.append(linear_point + offset)

	points.append(end)
	return points


func _emit_sparks_at_hits() -> void:
	# Emit sparks at each hit position except the first
	if chain_positions.size() < 2:
		return

	# Use the last position for sparks (final hit)
	sparks.global_position = chain_positions[chain_positions.size() - 1]
	sparks.emitting = true


func _on_lifetime_complete() -> void:
	queue_free()


## Configure lightning bolt
func configure(p_damage: float, p_chain_positions: Array[Vector2], p_width: float = 3.0, p_duration: float = 0.15) -> void:
	damage = p_damage
	chain_positions = p_chain_positions
	bolt_width = p_width
	display_duration = p_duration

	if is_node_ready():
		bolt_line.width = bolt_width
		lifetime_timer.wait_time = display_duration
		_generate_jagged_bolt()
		_emit_sparks_at_hits()
