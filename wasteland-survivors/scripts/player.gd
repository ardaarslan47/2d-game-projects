class_name Player
extends CharacterBody2D

## Player character controller for top-down 8-directional movement.
## Handles input, movement, and acts as the base for weapon management.

# Signals
signal health_changed(new_health: int, max_health: int)
signal died

# Exported variables
@export var max_health: int = 100
@export var move_speed: float = 100.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0
@export var invincibility_duration: float = 1.0  # Invincibility frames duration
@export var knockback_force: float = 200.0  # Knockback strength

# Public variables
var current_health: int = max_health
var is_alive: bool = true
var is_invincible: bool = false

# Private variables
var _input_direction: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _invincibility_timer: float = 0.0
var _original_modulate: Color
var _hit_effect_tween: Tween

# Onready variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var weapon_manager: WeaponManager = $WeaponManager

# Current direction for animation
var _current_animation: String = "south"

func _ready() -> void:
	current_health = max_health
	add_to_group("player")
	health_changed.emit(current_health, max_health)

	# Store original sprite modulate for restoration after hit effects
	_original_modulate = sprite.modulate

	# Set initial animation
	_current_animation = "down"
	sprite.animation = _current_animation
	sprite.frame = 0
	sprite.stop()

	# Add starting weapon
	weapon_manager.add_weapon_by_name("Rusty Pistol")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Handle invincibility timer
	if _invincibility_timer > 0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			is_invincible = false

			# Stop the blinking tween
			if _hit_effect_tween:
				_hit_effect_tween.kill()
				_hit_effect_tween = null

			# Restore original sprite appearance
			sprite.modulate = _original_modulate

	_handle_input()
	_handle_movement(delta)

# Public methods
func take_damage(amount: int, attacker_position: Vector2 = global_position) -> void:
	if not is_alive or is_invincible:
		return

	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)

	# Apply hit effects
	_apply_hit_effects(attacker_position)

	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	if not is_alive:
		return

	current_health += amount
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()
	# TODO: Play death animation
	# TODO: Disable collision
	print("Player died!")

# Private methods
func _handle_input() -> void:
	_input_direction = Input.get_vector("left", "right", "up", "down")

func _handle_movement(delta: float) -> void:
	# Apply knockback velocity if present
	if _knockback_velocity.length() > 0:
		velocity = _knockback_velocity
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, friction * delta * 2)
	elif _input_direction != Vector2.ZERO:
		# Normalize for consistent diagonal speed
		var move_direction := _input_direction.normalized()
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)

		# Update sprite direction based on movement
		_update_sprite_direction(move_direction)

		# Play animation if not already playing
		if not sprite.is_playing():
			sprite.play(_current_animation)
	else:
		# Apply friction when not moving
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

		# Stop animation and show first frame when idle
		if sprite.is_playing():
			sprite.stop()
			sprite.frame = 3

	move_and_slide()

func _update_sprite_direction(direction: Vector2) -> void:
	# Determine animation based on vertical vs horizontal movement
	var abs_x: float = abs(direction.x)
	var abs_y: float = abs(direction.y)

	var new_animation: String = _current_animation
	var new_flip: bool = sprite.flip_h

	# Prioritize vertical movement only if it's significantly stronger than horizontal
	# This makes diagonal movement use side animation
	if abs_y > abs_x * 1.5:  # Vertical must be 1.5x stronger to dominate
		if direction.y < 0:
			new_animation = "up"
			new_flip = false
		else:
			new_animation = "down"
			new_flip = false
	else:  # Horizontal dominates or diagonal
		new_animation = "side"
		# Flip sprite for left movement
		new_flip = direction.x < 0

	# Only change animation if direction changed
	if new_animation != _current_animation:
		_current_animation = new_animation
		sprite.animation = _current_animation

	# Update flip state
	sprite.flip_h = new_flip

func _apply_hit_effects(attacker_position: Vector2) -> void:
	# Activate invincibility
	is_invincible = true
	_invincibility_timer = invincibility_duration

	# Calculate knockback direction (away from attacker)
	var knockback_direction := global_position.direction_to(attacker_position) * -1
	_knockback_velocity = knockback_direction * knockback_force

	# Start visual effects
	_start_hit_visual_effects()

func _start_hit_visual_effects() -> void:
	# Kill any existing tween
	if _hit_effect_tween:
		_hit_effect_tween.kill()

	# Red flash effect
	sprite.modulate = Color(1, 0.3, 0.3, 0.5)  # Red and half transparent

	# Create a tween for blinking effect during invincibility
	_hit_effect_tween = create_tween()
	_hit_effect_tween.set_loops(int(invincibility_duration * 5))  # Blink 5 times per second

	# Blink between half opacity and more transparent (only affect alpha, keep red color)
	_hit_effect_tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	_hit_effect_tween.tween_property(sprite, "modulate:a", 0.5, 0.1)

	# The _physics_process timer will handle stopping the tween and restoring appearance
