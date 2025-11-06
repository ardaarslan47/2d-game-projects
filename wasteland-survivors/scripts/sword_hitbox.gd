class_name SwordHitbox
extends Area2D

## Sword melee hitbox - short-lived cone-shaped attack area.
## Deals damage and knockback to enemies in range.

# Hitbox parameters (set by weapon)
var damage: int = 10
var cone_angle: float = 20.0  # Degrees
var cone_range: float = 150.0  # Pixels
var knockback_force: float = 300.0
var owner_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.1  # How long the hitbox exists

# Private variables
var _hit_enemies: Array[Node] = []  # Track which enemies we've already hit
var _lifetime_timer: float = 0.0

# Onready variables
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var visual_polygon: Polygon2D = $VisualPolygon

func _ready() -> void:
	# Set collision layers (same as projectiles)
	collision_layer = 4  # Weapon layer
	collision_mask = 2  # Enemy layer

	# Connect to body_entered signal
	body_entered.connect(_on_body_entered)

	# Set position
	global_position = owner_position

	# Note: _generate_cone_shape() is called externally after parameters are set

func _process(delta: float) -> void:
	_lifetime_timer += delta

	if _lifetime_timer >= lifetime:
		queue_free()

func _generate_cone_shape() -> void:
	"""Generate a cone-shaped polygon for collision and visuals."""
	var cone_angle_rad: float = deg_to_rad(cone_angle)

	# Calculate cone vertices
	var vertices: PackedVector2Array = PackedVector2Array()

	# Start at origin (apex of cone)
	vertices.append(Vector2.ZERO)

	# Generate arc points for the cone
	var num_segments: int = 8
	for i in range(num_segments + 1):
		var t: float = float(i) / float(num_segments)
		var angle: float = lerp(-cone_angle_rad / 2, cone_angle_rad / 2, t)

		# Rotate direction by angle
		var point_direction: Vector2 = direction.rotated(angle)
		var point: Vector2 = point_direction * cone_range

		vertices.append(point)

	# Set collision shape
	if collision_polygon:
		collision_polygon.polygon = vertices

	# Set visual shape (blue color)
	if visual_polygon:
		visual_polygon.polygon = vertices
		visual_polygon.color = Color(0.3, 0.5, 1.0, 0.4)  # Semi-transparent blue

func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with enemies."""
	if not body.is_in_group("enemies"):
		return

	# Don't hit the same enemy twice
	if body in _hit_enemies:
		return

	_hit_enemies.append(body)

	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Apply knockback
	if body is CharacterBody2D:
		var knockback_direction: Vector2 = owner_position.direction_to(body.global_position)
		body.velocity += knockback_direction * knockback_force

func set_size_multiplier(multiplier: float) -> void:
	"""Scale the cone range based on size multiplier (for upgrades)."""
	cone_range *= multiplier
	_generate_cone_shape()
