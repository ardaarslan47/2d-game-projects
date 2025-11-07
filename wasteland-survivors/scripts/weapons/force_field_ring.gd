class_name ForceFieldRing
extends Area2D

## Expanding damage ring that pushes enemies back

# Exported properties
@export var damage: float = 10.0
@export var start_radius: float = 50.0
@export var max_radius: float = 250.0
@export var expansion_speed: float = 200.0
@export var push_force: float = 300.0
@export var ring_width: float = 4.0

# Internal state
var current_radius: float = 0.0
var hit_enemies: Array[Node2D] = []

@onready var ring_line: Line2D = $RingLine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	current_radius = start_radius
	ring_line.width = ring_width
	_update_visual()
	_update_collision()


func _process(delta: float) -> void:
	# Expand ring
	current_radius += expansion_speed * delta

	if current_radius >= max_radius:
		queue_free()
		return

	# Update visuals and collision
	_update_visual()
	_update_collision()

	# Fade out as it expands
	var fade_progress := (current_radius - start_radius) / (max_radius - start_radius)
	modulate.a = 1.0 - fade_progress


func _update_visual() -> void:
	# Generate circular line
	var points: PackedVector2Array = []
	var segments := 64
	for i in range(segments + 1):  # +1 to close the circle
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * current_radius)
	ring_line.points = points


func _update_collision() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = current_radius


func _on_body_entered(body: Node2D) -> void:
	# Skip if already hit
	if body in hit_enemies:
		return

	hit_enemies.append(body)

	# Damage enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Apply knockback
	if body is CharacterBody2D:
		var knockback_dir := (body.global_position - global_position).normalized()
		body.velocity += knockback_dir * push_force


## Configure ring properties
func configure(p_damage: float, p_start_radius: float, p_max_radius: float, p_expansion_speed: float, p_push_force: float, p_width: float = 4.0) -> void:
	damage = p_damage
	start_radius = p_start_radius
	max_radius = p_max_radius
	expansion_speed = p_expansion_speed
	push_force = p_push_force
	ring_width = p_width

	current_radius = start_radius

	if is_node_ready():
		ring_line.width = ring_width
		_update_visual()
		_update_collision()
