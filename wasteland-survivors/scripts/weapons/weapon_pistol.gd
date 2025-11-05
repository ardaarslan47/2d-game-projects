class_name WeaponPistol
extends WeaponBase

## Rusty Pistol - Basic starting weapon.
## Medium damage, medium fire rate.

func _ready() -> void:
	super._ready()

	weapon_name = "Rusty Pistol"
	damage = 10
	fire_rate = 2.0  # 2 shots per second
	projectile_speed = 500.0
	projectile_count = 1
	spread_angle = 0.0
	pierce_count = 0
