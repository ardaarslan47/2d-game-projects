class_name EnemyBase
extends CharacterBody2D

## Base enemy class with chase AI and health system.
## All enemies inherit from this class.
## Supports object pooling for performance.

# Signals
signal died

# Exported variables
@export var move_speed: float = 80.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var xp_drop_amount: int = 20
@export var xp_shard_scene: PackedScene

# Public variables
var player: Node2D = null

# Private variables
var _attack_timer: float = 0.0
var _pool: EnemyPool = null  # Reference to object pool

# Onready variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("enemies")

	# Connect HealthComponent signals
	health_component.died.connect(_on_health_died)

	# Find player using utility
	player = NodeUtils.get_first_in_group(get_tree(), "player")

	# Play walk animation if it exists
	if sprite and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

	# Connect hitbox signals
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not health_component.is_alive:
		return

	# Update attack timer
	if _attack_timer > 0:
		_attack_timer -= delta

	# Chase player
	if NodeUtils.is_valid(player):
		_chase_player(delta)

# Public methods
func take_damage(amount: int) -> void:
	if not health_component.is_alive:
		return

	# Delegate damage to HealthComponent
	health_component.take_damage(amount)

	# Visual feedback (flash red)
	_flash_damage()

func set_pool(pool: EnemyPool) -> void:
	"""Set the object pool reference (called by EnemyPool)."""
	_pool = pool

func reset_state() -> void:
	"""Reset enemy state when pulling from pool."""
	_attack_timer = 0.0
	velocity = Vector2.ZERO

	# Reset health to max AND revive (is_alive flag)
	if health_component:
		health_component.current_health = health_component.max_health
		health_component.is_alive = true  # CRITICAL: Revive the enemy!

	# Reset sprite
	if sprite:
		sprite.modulate = Color(1, 1, 1)
		sprite.scale = Vector2(1, 1)  # Reset scale after death animation
		sprite.flip_h = false
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")

	# Re-enable collision (use set_deferred to match how we disable it)
	if collision:
		collision.set_deferred("disabled", false)

	# Re-enable hitbox
	if hitbox:
		hitbox.set_deferred("monitoring", true)
		hitbox.set_deferred("monitorable", true)

	# Find player reference
	player = NodeUtils.get_first_in_group(get_tree(), "player")

# Private methods
func _chase_player(delta: float) -> void:
	var direction := global_position.direction_to(player.global_position)

	# Always move toward player
	velocity = direction * move_speed
	move_and_slide()

	# Update sprite direction based on movement
	_update_sprite_direction(direction)

func _update_sprite_direction(direction: Vector2) -> void:
	if not sprite:
		return

	# Simple sprite flipping based on horizontal direction
	# Flip sprite when moving left
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

	# Keep playing walk animation
	if not sprite.is_playing():
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")

func _on_hitbox_body_entered(body: Node2D) -> void:
	# Only attack player and respect cooldown
	if _attack_timer > 0:
		return

	if body.is_in_group("player"):
		_attack_timer = attack_cooldown

		# Deal damage to player with knockback
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)

func _flash_damage() -> void:
	# Simple damage feedback - change color briefly
	if sprite:
		sprite.modulate = GameConstants.ENEMY_HIT_FLASH_COLOR
		await get_tree().create_timer(GameConstants.ENEMY_HIT_FLASH_DURATION).timeout
		if NodeUtils.is_valid(self) and sprite:
			sprite.modulate = Color(1, 1, 1)

# Signal handlers
func _on_health_died() -> void:
	died.emit()
	_drop_xp()

	# Play death animation - fade out and scale down
	var death_tween: Tween = create_tween()
	death_tween.set_parallel(true)  # Run both tweens at the same time
	death_tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	death_tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.3)

	# After animation completes, return to pool
	death_tween.tween_callback(_return_to_pool)

func _return_to_pool() -> void:
	"""Return this enemy to the pool, or free it if no pool is set."""
	if _pool:
		_pool.return_enemy(self)
	else:
		# No pool set, fall back to regular cleanup
		queue_free()

func _drop_xp() -> void:
	"""Drop XP shard at enemy position."""
	if not xp_shard_scene:
		# Load default XP shard if not set
		xp_shard_scene = preload("res://scenes/pickups/xp_shard.tscn")

	if xp_shard_scene:
		var xp_shard: XPShard = xp_shard_scene.instantiate()
		xp_shard.global_position = global_position
		xp_shard.xp_value = xp_drop_amount

		# Add to the same parent as the enemy (the game scene)
		get_parent().call_deferred("add_child", xp_shard)
