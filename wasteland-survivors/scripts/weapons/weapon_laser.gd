class_name WeaponLaser
extends WeaponContinuous

## Laser Beam weapon - continuous sweeping beam that locks onto nearest enemy.
## Beam Width increases damage area. Sweep Speed affects target switching.

# Laser specific
@export var beam_length: float = 400.0
@export var beam_width: float = 10.0
@export var sweep_speed: float = 5.0  # How fast beam rotates to target

var beam_width_multiplier: float = 1.0
var sweep_speed_multiplier: float = 1.0

# Beam scene instance
const BEAM_SCENE := preload("res://scenes/weapons/laser_beam.tscn")
var _laser_beam: LaserBeam = null

# Computed properties
var effective_beam_width: float:
	get: return beam_width * beam_width_multiplier

var effective_sweep_speed: float:
	get: return sweep_speed * sweep_speed_multiplier

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Laser Beam"
	base_damage = 20.0
	base_fire_rate = 4.0  # Damage ticks per second
	base_weapon_range = 400.0
	damage_interval = 0.25

	super._ready()
	_create_beam()
	print("WeaponLaser: Initialized with laser beam scene")

func _create_beam() -> void:
	"""Instantiate laser beam from scene."""
	_laser_beam = BEAM_SCENE.instantiate()
	add_child(_laser_beam)

	# Configure beam properties
	var tick_rate := damage_interval
	_laser_beam.configure(damage, weapon_range, effective_beam_width, tick_rate, effective_sweep_speed)

	print("WeaponLaser: Created beam with damage=", damage, " range=", weapon_range, " width=", effective_beam_width)

func _process_weapon(delta: float) -> void:
	# Update beam configuration if properties changed
	if _laser_beam:
		_laser_beam.damage_per_tick = damage
		_laser_beam.max_range = weapon_range
		_laser_beam.beam_width = effective_beam_width
		_laser_beam.sweep_speed = effective_sweep_speed

	# Call parent for damage timing
	super._process_weapon(delta)

func _apply_continuous_damage() -> void:
	"""Damage is handled by the laser beam scene itself."""
	# The LaserBeam node handles its own damage ticks
	fired.emit()

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Beam Width":
			beam_width_multiplier *= multiplier
		"Sweep Speed":
			sweep_speed_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
