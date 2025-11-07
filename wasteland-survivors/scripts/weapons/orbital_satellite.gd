class_name OrbitalSatellite
extends Node2D

## Satellite that orbits the player and fires projectiles at enemies

# Exported properties
@export var orbit_radius: float = 120.0
@export var orbit_speed: float = 2.0
@export var fire_rate: float = 1.0
@export var damage: float = 12.0
@export var projectile_range: float = 400.0
@export var satellite_size: float = 8.0

# Orbit state
var orbit_angle: float = 0.0
var player: Node2D = null

# Projectile scene
const PROJECTILE_SCENE := preload("res://scenes/weapons/orbital_projectile.tscn")

@onready var visual: Polygon2D = $Visual
@onready var projectile_spawn: Marker2D = $ProjectileSpawn
@onready var fire_cooldown: Timer = $FireCooldown


func _ready() -> void:
	_update_visual()
	fire_cooldown.wait_time = 1.0 / fire_rate
	fire_cooldown.start()


func _process(delta: float) -> void:
	if not NodeUtils.is_valid(player):
		return

	# Update orbit angle
	orbit_angle += orbit_speed * delta

	# Position satellite around player
	var offset := Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	global_position = player.global_position + offset


func _update_visual() -> void:
	# Generate circular polygon for satellite
	var points: PackedVector2Array = []
	var segments := 16
	for i in range(segments):
		var angle := (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * satellite_size)
	visual.polygon = points


func _on_fire_cooldown_timeout() -> void:
	if not NodeUtils.is_valid(player):
		return

	# Find nearest enemy
	var target: Node2D = _find_nearest_enemy()
	if not NodeUtils.is_valid(target):
		return

	# Spawn projectile
	var projectile: OrbitalProjectile = PROJECTILE_SCENE.instantiate()
	get_tree().root.add_child(projectile)

	# Configure projectile
	var direction: Vector2 = global_position.direction_to(target.global_position)
	projectile.configure(damage, 300.0, direction, projectile_range / 300.0)  # lifetime based on range
	projectile.global_position = projectile_spawn.global_position


func _find_nearest_enemy() -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = projectile_range

	for enemy in enemies:
		if not NodeUtils.is_valid(enemy):
			continue

		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest


## Configure satellite properties
func configure(p_orbit_radius: float, p_orbit_speed: float, p_fire_rate: float, p_damage: float, p_range: float, p_size: float) -> void:
	orbit_radius = p_orbit_radius
	orbit_speed = p_orbit_speed
	fire_rate = p_fire_rate
	damage = p_damage
	projectile_range = p_range
	satellite_size = p_size

	if is_node_ready():
		_update_visual()
		fire_cooldown.wait_time = 1.0 / fire_rate


## Set the player reference for orbiting
func set_player(p_player: Node2D) -> void:
	player = p_player


## Set initial orbit angle (to space out multiple satellites)
func set_orbit_angle(angle: float) -> void:
	orbit_angle = angle
