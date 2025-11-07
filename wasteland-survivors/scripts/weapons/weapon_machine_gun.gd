class_name WeaponMachineGun
extends WeaponProjectile

## Machine Gun weapon - fires rapidly in player movement direction.
## No auto-aim. Multi-shot fires simultaneously with angular spread.
## High fire rate, lower damage than pistol.

# Machine gun specific
var _last_movement_direction: Vector2 = Vector2.DOWN  # Default direction

# Bullet scene
const BULLET_SCENE := preload("res://scenes/weapons/machine_gun_bullet.tscn")

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Machine Gun"
	base_damage = 6.0  # Lower than pistol (10)
	base_fire_rate = 6.0  # Much faster than pistol (1.0)
	projectile_speed = 500.0
	projectile_count = 1
	base_weapon_range = 400.0
	pierce_count = 0
	projectile_spread_angle = 15.0  # Base spread for multi-shot
	multi_shot_delay = 0.0  # Simultaneous firing

	super._ready()
	print("WeaponMachineGun: Initialized with bullet scene")

func _process_weapon(delta: float) -> void:
	# Track player movement direction
	_update_movement_direction()

	# Call parent to handle multi-shot queue
	super._process_weapon(delta)

func _update_movement_direction() -> void:
	"""Track player's movement direction."""
	if not owner_node:
		return

	# Get player input direction from velocity or input
	var input_dir: Vector2 = Vector2.ZERO

	# Try to get from player's velocity (movement)
	if "velocity" in owner_node and owner_node.velocity.length() > 10.0:
		input_dir = owner_node.velocity.normalized()
	# Fallback: try to get input direction directly
	elif "_input_direction" in owner_node:
		input_dir = owner_node._input_direction

	# Update last direction if player is moving
	if input_dir.length() > 0.1:
		_last_movement_direction = input_dir.normalized()

func _get_target_directions() -> Array[Vector2]:
	"""Fire in player movement direction with spread."""
	# For single shot, just use last movement direction
	if total_projectile_count == 1:
		return [_last_movement_direction]

	# For multi-shot, create spread pattern
	var directions: Array[Vector2] = []
	for i in range(total_projectile_count):
		directions.append(_last_movement_direction)  # Base direction for spread calculation

	return directions

func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	"""Spawn machine gun bullet using scene."""
	# Instantiate bullet from scene
	var bullet: MachineGunBullet = BULLET_SCENE.instantiate()

	# Calculate direction with spread
	var final_direction: Vector2 = base_direction
	if projectile_spread_angle > 0 and total_projectile_count > 1:
		var angle_offset: float = _calculate_spread_offset(index, total_projectile_count)
		final_direction = base_direction.rotated(deg_to_rad(angle_offset))

	# Configure bullet properties
	var size_mult: float = projectile_size_multiplier if "projectile_size_multiplier" in self else 1.0
	bullet.configure(damage, projectile_speed, final_direction, size_mult)

	# Set initial position
	bullet.global_position = get_owner_position()

	# Add to scene
	get_tree().current_scene.call_deferred("add_child", bullet)

	print("WeaponMachineGun: Spawned bullet at ", bullet.global_position, " with damage=", damage, " speed=", projectile_speed)

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Multi-Shot":
			projectile_count_bonus += int(multiplier)
			# Increase spread angle as projectile count increases
			projectile_spread_angle = min(15.0 + (total_projectile_count * 5.0), 360.0)
		"Projectile Speed":
			projectile_speed *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
