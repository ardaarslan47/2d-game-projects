class_name WeaponSword
extends WeaponBase

## Rusty Sword - Melee weapon with cone-shaped slash attack.
## Short range, medium damage, knockback on hit.

# Sword-specific properties
var cone_angle: float = 20.0  # Degrees
var knockback_force: float = 300.0
var cone_angle_bonus: float = 0.0  # Bonus from upgrades

func _ready() -> void:
	super._ready()

	weapon_name = "Rusty Sword"
	damage = 12
	fire_rate = 1.25  # 1.25 attacks per second (0.8s cooldown)
	weapon_range = 100.0  # Short range melee weapon
	projectile_count = 1  # Single slash
	pierce_count = 999  # Hits all enemies in cone

	# Use sword hitbox instead of default projectile
	projectile_scene = preload("res://scenes/weapons/sword_hitbox.tscn")

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

## Upgrade cone angle (for size/area upgrades).
func upgrade_cone_angle(bonus_angle: float) -> void:
	cone_angle_bonus += bonus_angle
	print("Sword cone angle upgraded by +%.1f degrees (total: %.1f degrees)" % [bonus_angle, cone_angle + cone_angle_bonus])
