class_name WeaponPistol
extends WeaponBase

## Rusty Pistol - Basic starting weapon.
## Medium damage, medium fire rate.

func _ready() -> void:
	super._ready()

	weapon_name = "Rusty Pistol"
	damage = 10
	fire_rate = 1.0  # 1 shot per second
	projectile_speed = 500.0
	projectile_count = 1
	spread_angle = 0.0
	pierce_count = 0
	weapon_range = 250.0  # Medium range weapon
