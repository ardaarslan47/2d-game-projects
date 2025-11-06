class_name EnemyZombieCat
extends EnemyBase

## Zombie Cat - Fast enemy type that spawns in packs.
## High speed, low HP, appears in waves starting at 1 minute.

func _ready() -> void:
	super._ready()

	# Zombie Cat stats - fast and fragile
	var base_speed: float = 100.0  # 66% faster than zombies
	var speed_multiplier: float = GameManager.get_movement_speed_multiplier()
	move_speed = base_speed * speed_multiplier

	damage = 5  # Less damage than zombies
	attack_cooldown = 1.0  # Faster attack rate
	xp_drop_amount = 15  # Less XP than zombies

	# Health is managed by HealthComponent and set by EnemySpawner
	# Zombie cats have lower base health (handled by custom scaling)

	# Play side animation instead of walk
	if sprite and sprite.sprite_frames.has_animation("side"):
		sprite.play("side")

func _update_sprite_direction(direction: Vector2) -> void:
	if not sprite:
		return

	# Use side animation and flip for left/right
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

	# Keep playing side animation
	if not sprite.is_playing():
		if sprite.sprite_frames.has_animation("side"):
			sprite.play("side")

func reset_state() -> void:
	"""Override reset_state to use 'side' animation."""
	super.reset_state()

	# Override animation reset
	if sprite and sprite.sprite_frames.has_animation("side"):
		sprite.play("side")
