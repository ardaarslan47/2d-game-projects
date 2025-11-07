class_name WeaponSword
extends WeaponProjectile

## Rusty Sword - Melee weapon with cone-shaped slash attack.
## Short range, medium damage, knockback on hit.

# Sword-specific properties
var cone_angle: float = 20.0  # Degrees
var knockback_force: float = 300.0
var cone_angle_bonus: float = 0.0  # Bonus from upgrades
var base_detection_range: float = 1.3  # Base detection multiplier for stationary enemies
var speed_reaction_time: float = 0.6  # How many seconds ahead to predict enemy position
var debug_detection: bool = false  # Set to true to see detection ranges in console

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Rusty Sword"
	base_damage = 12.0
	base_fire_rate = 1.25  # 1.25 attacks per second (0.8s cooldown)
	base_weapon_range = 100.0  # Short range melee weapon (actual attack range)
	projectile_count = 1  # Single slash
	pierce_count = 999  # Hits all enemies in cone
	multi_shot_delay = 0.05

	# Use sword hitbox instead of default projectile
	projectile_scene = preload("res://scenes/weapons/sword_hitbox.tscn")

	super._ready()

	print("Sword initialized: Attack range = %.0f, Base detection = %.0f (%.1fx), Speed-reactive enabled" % [weapon_range, weapon_range * base_detection_range, base_detection_range])

## Override projectile spawning to create melee hitbox instead.
func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	if not owner_node:
		return

	if not projectile_scene:
		push_error("WeaponSword: No sword_hitbox scene configured")
		return

	# Instantiate sword hitbox
	var hitbox: SwordHitbox = projectile_scene.instantiate()

	# Setup hitbox parameters BEFORE adding to tree
	var final_damage: int = int(damage * damage_multiplier)
	var final_cone_angle: float = cone_angle + cone_angle_bonus

	hitbox.damage = final_damage
	hitbox.cone_angle = final_cone_angle
	hitbox.cone_range = weapon_range
	hitbox.knockback_force = knockback_force
	hitbox.owner_position = owner_node.global_position
	hitbox.direction = base_direction
	hitbox.lifetime = 0.15  # Hitbox exists for 0.15 seconds

	# Apply size multiplier to cone range
	if projectile_size_multiplier > 1.0:
		hitbox.cone_range *= projectile_size_multiplier

	# Add to scene tree
	get_tree().current_scene.add_child(hitbox)

	# Generate cone shape AFTER all parameters are set
	hitbox._generate_cone_shape()

## Override target finding to detect enemies earlier based on their speed.
## This allows the sword to swing before fast enemies reach the player.
## Detection range dynamically adjusts: faster enemies = detected earlier.
func _find_multiple_target_directions(count: int) -> Array[Vector2]:
	"""Find directions to multiple nearest enemies using speed-reactive detection."""
	var enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	if enemies.is_empty() or not owner_node:
		return []

	var owner_pos: Vector2 = owner_node.global_position
	var target_directions: Array[Vector2] = []

	# Get all enemies with speed-adjusted detection ranges
	var enemies_in_range: Array[Dictionary] = []
	for enemy in enemies:
		var distance: float = owner_pos.distance_to(enemy.global_position)

		# Calculate dynamic detection range based on enemy speed
		var enemy_speed: float = 0.0
		enemy_speed = enemy.velocity.length()

		# Detection range = base range + (speed * reaction time)
		# Fast enemies get detected much earlier
		var dynamic_detection_range: float = (weapon_range * base_detection_range) + (enemy_speed * speed_reaction_time)

		if distance <= dynamic_detection_range:
			enemies_in_range.append({
				"enemy": enemy,
				"distance": distance,
				"detection_range": dynamic_detection_range  # Store for debugging
			})

	if enemies_in_range.is_empty():
		return []

	# Sort by distance (closest first)
	enemies_in_range.sort_custom(func(a, b): return a.distance < b.distance)

	# Get directions to nearest enemies
	for i in range(count):
		var target_index: int = i % enemies_in_range.size()
		var enemy: Node = enemies_in_range[target_index].enemy
		var direction: Vector2 = owner_pos.direction_to(enemy.global_position)
		target_directions.append(direction)

	return target_directions

## Upgrade cone angle (for size/area upgrades).
func upgrade_cone_angle(bonus_angle: float) -> void:
	cone_angle_bonus += bonus_angle
	print("Sword cone angle upgraded by +%.1f degrees (total: %.1f degrees)" % [bonus_angle, cone_angle + cone_angle_bonus])
