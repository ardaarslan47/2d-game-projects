class_name EnemyBigZombie
extends EnemyBase

## Big Zombie - Elite enemy variant.
## Spawns every minute (1:00, 2:00, 3:00, 4:00).
## 3x health, larger sprite, higher XP reward.

func _ready() -> void:
	super._ready()

	# Big zombie stats - similar to regular zombie but tankier
	var base_speed: float = 60.0
	var speed_multiplier: float = GameManager.get_movement_speed_multiplier()
	move_speed = base_speed * speed_multiplier

	damage = 15  # Slightly higher damage
	attack_cooldown = 1.5
	xp_drop_amount = 30  # 3x XP reward (regular zombie = 10)

	# Scale up sprite to 1.5x
	if sprite:
		sprite.scale = Vector2(1.5, 1.5)

	# Note: Health multiplier (3x) applied in EnemySpawner
	# HealthComponent will be configured by spawner with scaled health
