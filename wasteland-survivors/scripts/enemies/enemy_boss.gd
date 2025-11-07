class_name EnemyBoss
extends EnemyBase

## Boss Enemy - Stage completion requirement.
## Spawns at 5:00, must be defeated to complete stage.
## 10x health, 1.5x speed, massive XP reward.

signal boss_defeated

func _ready() -> void:
	super._ready()

	# Boss stats - fast and extremely tanky
	var base_speed: float = 60.0
	var speed_multiplier: float = GameManager.get_movement_speed_multiplier()
	move_speed = base_speed * speed_multiplier * 1.5  # 1.5x speed bonus

	damage = 25  # High damage
	attack_cooldown = 1.0  # Fast attacks
	xp_drop_amount = 500  # Massive XP reward

	# Scale up sprite to 2.0x (boss size)
	if sprite:
		sprite.scale = Vector2(2.0, 2.0)

	# Add to "boss" group for tracking
	add_to_group("boss")

	# Note: Health multiplier (10x) applied in EnemySpawner
	# HealthComponent will be configured by spawner with scaled health

func _on_health_died() -> void:
	# Emit boss defeated signal before standard death behavior
	boss_defeated.emit()

	# Notify game controller about boss defeat
	get_tree().call_group("game_controller", "_on_boss_defeated")

	# Call parent death logic (drops XP, plays death animation, returns to pool)
	super._on_health_died()

func reset_state() -> void:
	super.reset_state()
	# Re-add to boss group after reset (pooling removes groups)
	add_to_group("boss")
