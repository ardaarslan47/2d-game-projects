class_name GrenadeProjectile
extends Node2D

## Grenade projectile that arcs through the air and explodes on impact

# Exported properties
@export var damage: float = 20.0
@export var speed: float = 250.0
@export var arc_height: float = 100.0
@export var explosion_radius: float = 80.0
@export var pierce_count: int = 0
@export var max_lifetime: float = 3.0

# Internal state
var target_position: Vector2
var start_position: Vector2
var travel_progress: float = 0.0
var distance: float = 0.0
var has_exploded: bool = false
var remaining_pierce: int = 0

# Explosion scene
const EXPLOSION_SCENE := preload("res://scenes/weapons/grenade_explosion.tscn")

@onready var visual: Polygon2D = $Visual
@onready var trail: CPUParticles2D = $Trail


func _ready() -> void:
	start_position = global_position
	distance = start_position.distance_to(target_position)
	remaining_pierce = pierce_count
	_update_visual()
	trail.emitting = true


func _physics_process(delta: float) -> void:
	if has_exploded:
		return

	# Update travel progress
	var travel_distance := speed * delta
	travel_progress += travel_distance / distance

	if travel_progress >= 1.0:
		# Reached target, explode
		_explode()
		return

	# Calculate arc position
	var linear_pos := start_position.lerp(target_position, travel_progress)
	var arc_offset := sin(travel_progress * PI) * arc_height
	global_position = linear_pos + Vector2(0, -arc_offset)

	# Update trail direction
	var velocity_dir := (global_position - start_position).normalized()
	trail.direction = -velocity_dir

	# Check lifetime
	if travel_progress * distance / speed >= max_lifetime:
		_explode()


func _update_visual() -> void:
	# Create circular polygon for grenade
	var points: PackedVector2Array = []
	var segments := 12
	var radius := 6.0
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	visual.polygon = points


func _explode() -> void:
	if has_exploded:
		return

	has_exploded = true

	# Spawn explosion
	var explosion: GrenadeExplosion = EXPLOSION_SCENE.instantiate()
	get_tree().root.add_child(explosion)
	explosion.global_position = global_position
	explosion.configure(damage, explosion_radius)

	# Check for pierce (re-explode at new location)
	if remaining_pierce > 0:
		remaining_pierce -= 1
		# Find another target and create another grenade
		var new_target: Node2D = _find_nearest_enemy()
		if NodeUtils.is_valid(new_target):
			var new_grenade: GrenadeProjectile = get_script().new()
			get_tree().root.call_deferred("add_child", new_grenade)
			new_grenade.configure(damage, speed, global_position, new_target.global_position, arc_height, explosion_radius, remaining_pierce)

	# Remove this grenade
	queue_free()


func _find_nearest_enemy() -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = 500.0  # Search range

	for enemy in enemies:
		if not NodeUtils.is_valid(enemy):
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest


## Configure grenade properties
func configure(p_damage: float, p_speed: float, p_start: Vector2, p_target: Vector2, p_arc: float, p_explosion_radius: float, p_pierce: int = 0) -> void:
	damage = p_damage
	speed = p_speed
	start_position = p_start
	target_position = p_target
	arc_height = p_arc
	explosion_radius = p_explosion_radius
	pierce_count = p_pierce
	remaining_pierce = p_pierce

	global_position = start_position
	distance = start_position.distance_to(target_position)

	if is_node_ready():
		_update_visual()
