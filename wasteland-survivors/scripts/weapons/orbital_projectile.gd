class_name OrbitalProjectile
extends Area2D

## Projectile fired by orbital satellites

# Exported properties
@export var damage: float = 12.0
@export var speed: float = 300.0
@export var max_lifetime: float = 2.0
@export var projectile_size: float = 4.0

# Internal state
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var trail: CPUParticles2D = $Trail


func _ready() -> void:
	_update_visual()
	trail.emitting = true


func _physics_process(delta: float) -> void:
	# Move projectile
	global_position += direction * speed * delta

	# Update trail direction (opposite of movement)
	trail.direction = -direction

	# Update lifetime
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()


func _update_visual() -> void:
	# Create small circular polygon
	var points: PackedVector2Array = []
	var segments := 8
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * projectile_size)
	visual.polygon = points


func _on_body_entered(body: Node2D) -> void:
	# Damage enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Projectile disappears on hit
	queue_free()


## Configure projectile properties
func configure(p_damage: float, p_speed: float, p_direction: Vector2, p_lifetime: float = 2.0, p_size: float = 4.0) -> void:
	damage = p_damage
	speed = p_speed
	direction = p_direction.normalized()
	max_lifetime = p_lifetime
	projectile_size = p_size

	if is_node_ready():
		_update_visual()
