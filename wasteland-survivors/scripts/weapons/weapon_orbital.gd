class_name WeaponOrbital
extends WeaponContinuous

## Orbital weapon - satellites orbit the player and auto-fire at enemies.
## Satellite Count upgrade adds more orbitals.
## Orbit Speed affects rotation speed.

# Orbital specific
@export var satellite_count: int = 2
@export var orbit_radius: float = 60.0
@export var orbit_speed: float = 1.0  # Rotations per second

var satellite_count_bonus: int = 0
var orbit_speed_multiplier: float = 1.0

# Satellite scene
const SATELLITE_SCENE := preload("res://scenes/weapons/orbital_satellite.tscn")
var _satellites: Array[OrbitalSatellite] = []

# Computed properties
var total_satellite_count: int:
	get: return satellite_count + satellite_count_bonus

var effective_orbit_speed: float:
	get: return orbit_speed * orbit_speed_multiplier

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Orbital Satellites"
	base_damage = 12.0
	base_fire_rate = 1.5  # Each satellite fires 1.5 times per second
	base_weapon_range = 250.0
	damage_interval = 0.67  # Base interval for each satellite

	super._ready()
	_create_satellites()
	print("WeaponOrbital: Initialized with satellite scene")

func _create_satellites() -> void:
	"""Create satellite nodes from scene."""
	_clear_satellites()

	for i in range(total_satellite_count):
		var satellite: OrbitalSatellite = SATELLITE_SCENE.instantiate()
		add_child(satellite)

		# Configure satellite
		var initial_angle := (float(i) / total_satellite_count) * TAU
		satellite.configure(orbit_radius, effective_orbit_speed, fire_rate, damage, weapon_range, 8.0)
		satellite.set_player(owner_node if owner_node else get_parent().get_parent())
		satellite.set_orbit_angle(initial_angle)

		_satellites.append(satellite)

	print("WeaponOrbital: Created ", _satellites.size(), " satellites")

func _clear_satellites() -> void:
	"""Remove all existing satellites."""
	for satellite in _satellites:
		if NodeUtils.is_valid(satellite):
			satellite.queue_free()
	_satellites.clear()

func _process_weapon(delta: float) -> void:
	# Update satellites if properties changed
	for satellite in _satellites:
		if NodeUtils.is_valid(satellite):
			satellite.orbit_radius = orbit_radius
			satellite.orbit_speed = effective_orbit_speed
			satellite.damage = damage
			satellite.projectile_range = weapon_range

	# Recreate satellites if count changed
	if _satellites.size() != total_satellite_count:
		_create_satellites()

	# Call parent
	super._process_weapon(delta)

func _apply_continuous_damage() -> void:
	"""Damage is handled by individual satellites."""
	# Satellites handle their own firing
	pass

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Satellite Count":
			satellite_count_bonus += int(multiplier)
			_create_satellites()
		"Orbit Speed":
			orbit_speed_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
