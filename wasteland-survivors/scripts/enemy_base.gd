class_name EnemyBase
extends CharacterBody2D

## Base enemy class with chase AI and health system.
## All enemies inherit from this class.

# Signals
signal died

# Exported variables
@export var move_speed: float = 80.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0

# Public variables
var player: Node2D = null

# Private variables
var _attack_timer: float = 0.0

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
	# TODO: Drop XP
	# TODO: Play death animation
	queue_free()
