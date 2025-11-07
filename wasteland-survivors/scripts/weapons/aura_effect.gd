class_name AuraEffect
extends Area2D

## Circular damage aura that periodically damages enemies within radius

# Exported properties
@export var damage_per_tick: float = 8.0
@export var radius: float = 100.0

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var floating_particles: CPUParticles2D = $FloatingParticles
@onready var damage_tick: Timer = $DamageTick


func _ready() -> void:
	_update_visual()
	_update_collision()
	_update_particles()


func _on_damage_tick() -> void:
	# Damage all enemies in the aura
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage_per_tick)


func _update_visual() -> void:
	# Generate circle polygon
	var points: PackedVector2Array = []
	var segments := 64
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points


func _update_collision() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


func _update_particles() -> void:
	floating_particles.emission_sphere_radius = radius


## Configure aura properties
func configure(p_damage: float, p_radius: float, p_tick_rate: float) -> void:
	damage_per_tick = p_damage
	radius = p_radius

	if is_node_ready():
		_update_visual()
		_update_collision()
		_update_particles()
		damage_tick.wait_time = p_tick_rate


## Update radius (called when upgraded)
func set_radius(new_radius: float) -> void:
	radius = new_radius
	if is_node_ready():
		_update_visual()
		_update_collision()
		_update_particles()
