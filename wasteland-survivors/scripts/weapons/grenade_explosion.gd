class_name GrenadeExplosion
extends Area2D

## Explosion effect that damages enemies in radius and expands visually

# Exported properties
@export var damage: float = 20.0
@export var radius: float = 80.0

# Internal state
var has_damaged: bool = false
var start_radius: float = 10.0
var current_scale: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var explosion_particles: CPUParticles2D = $ExplosionParticles
@onready var expand_timer: Timer = $ExpandTimer


func _ready() -> void:
	# Set target radius
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius

	# Start small
	current_scale = start_radius / radius
	scale = Vector2.ONE * current_scale

	# Generate circle visual
	_update_visual()

	# Emit particles
	explosion_particles.emitting = true

	# Damage on spawn
	call_deferred("_damage_enemies")


func _process(delta: float) -> void:
	# Expand animation
	if current_scale < 1.0:
		current_scale = min(current_scale + delta * 10.0, 1.0)
		scale = Vector2.ONE * current_scale

		# Fade out as it expands
		modulate.a = 1.0 - current_scale


func _update_visual() -> void:
	# Generate circle polygon
	var points: PackedVector2Array = []
	var segments := 32
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points


func _damage_enemies() -> void:
	if has_damaged:
		return

	has_damaged = true

	# Get all overlapping enemies
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)


func _on_expand_complete() -> void:
	# Cleanup after expansion
	await get_tree().create_timer(0.5).timeout
	queue_free()


## Configure explosion properties
func configure(p_damage: float, p_radius: float) -> void:
	damage = p_damage
	radius = p_radius

	if is_node_ready():
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = radius
		_update_visual()
