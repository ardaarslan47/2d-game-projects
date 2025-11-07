class_name HomingMissileProjectile
extends Area2D

## Homing missile that tracks targets and can pierce through enemies

# Exported properties
@export var damage: float = 18.0
@export var speed: float = 180.0
@export var pierce_count: int = 0
@export var homing_strength: float = 5.0
@export var max_lifetime: float = 4.0
@export var missile_size: float = 8.0

# Internal state
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var target: Node2D = null
var remaining_pierce: int = 0
var hit_enemies: Array[Node2D] = []

@onready var visual: Polygon2D = $Visual
@onready var thrust_trail: CPUParticles2D = $ThrustTrail


func _ready() -> void:
	remaining_pierce = pierce_count
	_update_visual()
	thrust_trail.emitting = true


func _physics_process(delta: float) -> void:
	# Update lifetime
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return

	# Home in on target if valid
	if NodeUtils.is_valid(target):
		var to_target: Vector2 = global_position.direction_to(target.global_position)
		var target_angle: float = to_target.angle()
		var current_angle: float = direction.angle()

		# Smoothly rotate toward target
		var angle_diff: float = _angle_difference(current_angle, target_angle)
		var max_rotation: float = homing_strength * delta
		var rotation_amount: float = clamp(angle_diff, -max_rotation, max_rotation)

		direction = direction.rotated(rotation_amount)
		rotation = direction.angle()
	else:
		# Target lost, try to find new one
		target = _find_nearest_enemy()

	# Move missile
	global_position += direction * speed * delta

	# Update thrust trail direction (opposite of movement)
	thrust_trail.direction = -direction.rotated(-rotation)


func _update_visual() -> void:
	# Create triangular polygon for missile
	var half_length := missile_size
	var half_width := missile_size * 0.4

	var points: PackedVector2Array = [
		Vector2(half_length, 0),      # Tip
		Vector2(-half_length, half_width),   # Bottom left
		Vector2(-half_length, -half_width)   # Top left
	]
	visual.polygon = points


func _on_body_entered(body: Node2D) -> void:
	# Skip if already hit this enemy (for pierce)
	if body in hit_enemies:
		return

	# Damage enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		hit_enemies.append(body)

	# Check pierce
	if remaining_pierce > 0:
		remaining_pierce -= 1
		# Find new target
		target = _find_nearest_enemy()
	else:
		# No pierce left, destroy missile
		queue_free()


func _find_nearest_enemy() -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not NodeUtils.is_valid(enemy):
			continue

		# Skip enemies already hit
		if enemy in hit_enemies:
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest


func _angle_difference(from: float, to: float) -> float:
	var diff := fmod(to - from, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff


## Configure missile properties
func configure(p_damage: float, p_speed: float, p_direction: Vector2, p_target: Node2D, p_homing: float, p_pierce: int = 0, p_size: float = 8.0) -> void:
	damage = p_damage
	speed = p_speed
	direction = p_direction.normalized()
	target = p_target
	homing_strength = p_homing
	pierce_count = p_pierce
	remaining_pierce = p_pierce
	missile_size = p_size

	rotation = direction.angle()

	if is_node_ready():
		_update_visual()
