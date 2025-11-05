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
	attack_cooldown = 1.5

	# Start walk animation
	if sprite:
		sprite.play("walk")

func _update_sprite_direction(direction: Vector2) -> void:
	# Always use walk animation, just flip horizontally based on direction
	if sprite and not sprite.is_playing():
		sprite.play("walk")

	# Flip sprite based on horizontal direction
	if sprite:
		sprite.flip_h = direction.x < 0
