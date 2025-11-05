class_name EnemyZombie
extends EnemyBase

## Zombie Scavenger - Basic enemy type.
## Slow movement, medium HP, standard melee threat.

func _ready() -> void:
	super._ready()

	# Zombie stats
	max_health = 30
	current_health = max_health
	move_speed = 60.0
	damage = 10
	attack_range = 25.0
	attack_cooldown = 1.5
