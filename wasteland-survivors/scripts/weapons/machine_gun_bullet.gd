class_name MachineGunBullet
extends Area2D

## Machine gun projectile with configurable properties

# Exported properties for weapon to configure
@export var damage: float = 10.0
@export var speed: float = 400.0
@export var size_multiplier: float = 1.0
@export var max_lifetime: float = 3.0

# Internal state
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	# Apply size multiplier to visual
	visual.scale = Vector2.ONE * size_multiplier

	# Apply size to collision shape
	var collision_shape: CollisionShape2D = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = 4.0 * size_multiplier


func _physics_process(delta: float) -> void:
	# Move in direction
	global_position += direction * speed * delta

	# Track lifetime and auto-cleanup
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Damage enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Bullet disappears on hit
	queue_free()


## Configure bullet properties (called by weapon before adding to tree)
func configure(p_damage: float, p_speed: float, p_direction: Vector2, p_size_mult: float = 1.0) -> void:
	damage = p_damage
	speed = p_speed
	direction = p_direction.normalized()
	size_multiplier = p_size_mult
