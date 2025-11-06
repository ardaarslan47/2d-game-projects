class_name Player
extends CharacterBody2D

## Player character controller for top-down 8-directional movement.
## Handles input, movement, and acts as the base for weapon management.

# Signals
signal health_changed(new_health: int, max_health: int)
signal died

# Exported variables
@export var move_speed: float = 100.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0
@export var invincibility_duration: float = 1.0  # Invincibility frames duration
@export var knockback_force: float = 200.0  # Knockback strength

# Public variables
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
@onready var health_component: HealthComponent = $HealthComponent

# Current direction for animation
var _current_animation: String = GameConstants.PLAYER_DEFAULT_ANIMATION

func _ready() -> void:
	add_to_group("player")

	# Connect HealthComponent signals
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_health_died)

	# Emit initial health state
	health_changed.emit(health_component.current_health, health_component.max_health)

	# Store original sprite modulate for restoration after hit effects
	_original_modulate = sprite.modulate

	# Set initial animation
	sprite.animation = _current_animation
	sprite.frame = 0
	sprite.stop()

	# Add starting weapon
	weapon_manager.add_weapon_by_name("Rusty Pistol")

func _physics_process(delta: float) -> void:
	if not health_component.is_alive:
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
	if not health_component.is_alive or is_invincible:
		return

	# Delegate damage to HealthComponent
	health_component.take_damage(amount)

	# Apply hit effects (knockback and visuals)
	_apply_hit_effects(attacker_position)

func heal(amount: int) -> void:
	health_component.heal(amount)

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

		# Stop animation and show idle frame
		if sprite.is_playing():
			sprite.stop()
			sprite.frame = GameConstants.PLAYER_IDLE_FRAME

	move_and_slide()

func _update_sprite_direction(direction: Vector2) -> void:
	# Determine animation based on vertical vs horizontal movement
	var abs_x: float = abs(direction.x)
	var abs_y: float = abs(direction.y)

	var new_animation: String = _current_animation
	var new_flip: bool = sprite.flip_h

	# Prioritize vertical movement only if it's significantly stronger than horizontal
	# This makes diagonal movement use side animation
	if abs_y > abs_x * GameConstants.PLAYER_VERTICAL_DOMINANCE:
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
	sprite.modulate = GameConstants.PLAYER_HIT_FLASH_COLOR

	# Create a tween for blinking effect during invincibility
	_hit_effect_tween = create_tween()
	_hit_effect_tween.set_loops(int(invincibility_duration * GameConstants.PLAYER_BLINK_RATE))

	# Blink between half opacity and more transparent (only affect alpha, keep red color)
	_hit_effect_tween.tween_property(sprite, "modulate:a", GameConstants.PLAYER_HIT_FLASH_ALPHA_MIN, GameConstants.PLAYER_HIT_FLASH_TWEEN_DURATION)
	_hit_effect_tween.tween_property(sprite, "modulate:a", GameConstants.PLAYER_HIT_FLASH_ALPHA_MAX, GameConstants.PLAYER_HIT_FLASH_TWEEN_DURATION)

	# The _physics_process timer will handle stopping the tween and restoring appearance

# Signal handlers
func _on_health_changed(current: int, maximum: int) -> void:
	health_changed.emit(current, maximum)

func _on_health_died() -> void:
	died.emit()
	# TODO: Play death animation
	# TODO: Disable collision
	print("Player died!")
