class_name EnemyBase
extends CharacterBody2D

## Base enemy class with chase AI and health system.
## All enemies inherit from this class.

# Signals
signal died

# Exported variables
@export var max_health: int = 30
@export var move_speed: float = 80.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0

# Public variables
var current_health: int = max_health
var is_alive: bool = true
var player: Node2D = null

# Private variables
var _attack_timer: float = 0.0

# Onready variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")

	# Find player
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

	# Play walk animation if it exists
	if sprite and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")

	# Connect hitbox signals
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Update attack timer
	if _attack_timer > 0:
		_attack_timer -= delta

	# Chase player
	if player and is_instance_valid(player):
		_chase_player(delta)

# Public methods
func take_damage(amount: int) -> void:
	if not is_alive:
		return

	current_health -= amount

	# Visual feedback (flash red)
	_flash_damage()

	if current_health <= 0:
		die()

func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()

	# TODO: Drop XP
	# TODO: Play death animation

	queue_free()

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
		sprite.modulate = Color(1, 0.5, 0.5)
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = Color(1, 1, 1)
