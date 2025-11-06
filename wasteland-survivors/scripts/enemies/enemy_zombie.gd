class_name EnemyZombie
extends EnemyBase

## Zombie Scavenger - Basic enemy type.
## Slow movement, medium HP, standard melee threat.

func _ready() -> void:
	super._ready()

	# Zombie stats - override base values
	# Note: max_health is now managed by HealthComponent
	# Set it via @export in the scene or configure HealthComponent directly
	move_speed = 60.0
	damage = 10
	attack_cooldown = 1.5

	# HealthComponent will handle health initialization
	# Base class already handles walk animation
