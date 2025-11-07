class_name WeaponForceField
extends WeaponBaseNew

## Force Field weapon - periodically emits an expanding ring that damages and pushes enemies.
## Size upgrade increases ring radius. Push Force increases knockback.

# Force field specific
@export var max_ring_radius: float = 150.0
@export var ring_expansion_speed: float = 300.0  # Pixels per second
@export var push_force: float = 200.0

var push_force_multiplier: float = 1.0
var size_multiplier: float = 1.0

# Ring scene
const RING_SCENE := preload("res://scenes/weapons/force_field_ring.tscn")

# Computed properties
var effective_max_radius: float:
	get: return max_ring_radius * size_multiplier

var effective_push_force: float:
	get: return push_force * push_force_multiplier

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Force Field"
	base_damage = 15.0
	base_fire_rate = 0.5  # Once every 2 seconds
	base_weapon_range = 150.0

	super._ready()
	print("WeaponForceField: Initialized with force field ring scene")

func _execute_fire() -> void:
	"""Create a new expanding ring."""
	# Instantiate ring from scene
	var ring: ForceFieldRing = RING_SCENE.instantiate()

	# Configure ring
	ring.configure(damage, 50.0, effective_max_radius, ring_expansion_speed, effective_push_force)

	# Set position
	ring.global_position = get_owner_position()

	# Add to scene
	get_tree().current_scene.call_deferred("add_child", ring)

	fired.emit()
	print("WeaponForceField: Created expanding ring at ", ring.global_position)

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Size":
			size_multiplier *= multiplier
			base_weapon_range *= multiplier
		"Push Force":
			push_force_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
