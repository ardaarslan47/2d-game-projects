class_name WeaponHomingMissile
extends WeaponProjectile

## Homing Missiles weapon - slow-moving projectiles that track and pursue targets.
## Homing Strength affects turning speed. Pierce allows hitting multiple enemies.

# Homing specific
@export var homing_strength: float = 5.0  # Turning speed in radians per second

var homing_strength_multiplier: float = 1.0

# Missile scene
const MISSILE_SCENE := preload("res://scenes/weapons/homing_missile_projectile.tscn")

# Computed properties
var effective_homing_strength: float:
	get: return homing_strength * homing_strength_multiplier

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Homing Missiles"
	base_damage = 18.0
	base_fire_rate = 1.0
	projectile_speed = 180.0  # Slower than normal projectiles
	projectile_count = 2
	base_weapon_range = 400.0
	pierce_count = 0
	projectile_spread_angle = 10.0
	multi_shot_delay = 0.15

	super._ready()
	print("WeaponHomingMissile: Initialized with missile scene")

func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	"""Spawn homing missile using scene."""
	var target: Node = get_nearest_enemy()
	if not NodeUtils.is_valid(target):
		return

	# Instantiate missile from scene
	var missile: HomingMissileProjectile = MISSILE_SCENE.instantiate()

	# Calculate direction with spread
	var final_direction: Vector2 = base_direction
	if projectile_spread_angle > 0 and total_projectile_count > 1:
		var angle_offset: float = _calculate_spread_offset(index, total_projectile_count)
		final_direction = base_direction.rotated(deg_to_rad(angle_offset))

	# Configure missile
	missile.configure(damage, projectile_speed, final_direction, target, effective_homing_strength, pierce_count + pierce_bonus)

	# Set position
	missile.global_position = get_owner_position()

	# Add to scene
	get_tree().current_scene.call_deferred("add_child", missile)

	print("WeaponHomingMissile: Spawned missile at ", missile.global_position, " targeting enemy")

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Homing Strength":
			homing_strength_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
