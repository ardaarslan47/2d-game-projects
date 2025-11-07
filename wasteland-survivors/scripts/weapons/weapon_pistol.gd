class_name WeaponPistol
extends WeaponProjectile

## Rusty Pistol - Basic starting weapon.
## Medium damage, medium fire rate, auto-targeting.

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Rusty Pistol"
	base_damage = 10.0
	base_fire_rate = 1.0  # 1 shot per second
	projectile_speed = 500.0
	projectile_count = 1
	pierce_count = 0
	base_weapon_range = 250.0  # Medium range weapon
	multi_shot_delay = 0.05  # Delay between shots

	super._ready()
