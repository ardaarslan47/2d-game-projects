class_name LaserBeam
extends Node2D

## Continuous laser beam that tracks and damages targets

# Exported properties
@export var damage_per_tick: float = 5.0
@export var max_range: float = 400.0
@export var beam_width: float = 3.0
@export var sweep_speed: float = 5.0

# Internal state
var current_target: Node2D = null
var target_angle: float = 0.0
var current_angle: float = 0.0

@onready var beam_line: Line2D = $BeamLine
@onready var endpoint_particles: CPUParticles2D = $EndpointParticles
@onready var damage_tick: Timer = $DamageTick


func _ready() -> void:
	# Apply beam width
	beam_line.width = beam_width

	# Set damage tick interval
	damage_tick.wait_time = 1.0  # Will be overridden by weapon


func _process(delta: float) -> void:
	if not NodeUtils.is_valid(current_target):
		_find_new_target()

	if NodeUtils.is_valid(current_target):
		# Calculate target angle
		target_angle = global_position.angle_to_point(current_target.global_position)

		# Smoothly sweep to target
		var angle_diff: float = wrapf(target_angle - current_angle, -PI, PI)
		current_angle += angle_diff * sweep_speed * delta
		current_angle = wrapf(current_angle, -PI, PI)

		# Update beam visual
		_update_beam()
	else:
		# No target, hide beam
		beam_line.points = []
		endpoint_particles.emitting = false


func _update_beam() -> void:
	# Calculate beam endpoint
	var beam_direction := Vector2.from_angle(current_angle)
	var beam_end := beam_direction * max_range

	# Raycast to find actual hit point
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + beam_end)
	query.collision_mask = 2  # Enemy layer
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result := space_state.intersect_ray(query)
	if result:
		beam_end = to_local(result.position)

	# Update Line2D
	beam_line.points = [Vector2.ZERO, beam_end]

	# Update particles at endpoint
	endpoint_particles.global_position = global_position + beam_end
	endpoint_particles.emitting = true


func _find_new_target() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = max_range

	for enemy in enemies:
		if not NodeUtils.is_valid(enemy):
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	current_target = nearest


func _on_damage_tick() -> void:
	if not NodeUtils.is_valid(current_target):
		return

	# Check if target is within beam arc (tolerance for sweep)
	var to_target: float = global_position.angle_to_point(current_target.global_position)
	var angle_diff: float = abs(wrapf(to_target - current_angle, -PI, PI))

	if angle_diff < deg_to_rad(15):  # 15 degree tolerance
		if current_target.has_method("take_damage"):
			current_target.take_damage(damage_per_tick)


## Configure beam properties
func configure(p_damage: float, p_range: float, p_width: float, p_tick_rate: float, p_sweep_speed: float) -> void:
	damage_per_tick = p_damage
	max_range = p_range
	beam_width = p_width
	sweep_speed = p_sweep_speed

	if is_node_ready():
		beam_line.width = beam_width
		damage_tick.wait_time = p_tick_rate
