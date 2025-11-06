class_name EnemyZombie
extends EnemyBase

## Zombie Scavenger - Basic enemy type.
## Slow movement, medium HP, standard melee threat.

func _ready() -> void:
	super._ready()

	# Zombie stats - override base values
	# Note: max_health is now managed by HealthComponent
	# Set it via @export in the scene or configure HealthComponent directly

	# Apply difficulty scaling to movement speed
	var base_speed: float = 60.0
	var speed_multiplier: float = GameManager.get_movement_speed_multiplier()
	move_speed = base_speed * speed_multiplier

	damage = 10
	attack_cooldown = 1.5

	# HealthComponent will handle health initialization
	# Base class already handles walk animation
