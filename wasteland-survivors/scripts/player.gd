class_name Player
extends CharacterBody2D

## Player character controller for top-down 8-directional movement.
## Handles input, movement, and acts as the base for weapon management.

# Signals
signal health_changed(new_health: int, max_health: int)
signal died

# Exported variables
@export var max_health: int = 100
@export var move_speed: float = 200.0
@export var acceleration: float = 2000.0
@export var friction: float = 1500.0

# Public variables
var current_health: int = max_health
var is_alive: bool = true

# Private variables
var _input_direction: Vector2 = Vector2.ZERO

# Onready variables
@onready var sprite: ColorRect = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var weapon_manager: WeaponManager = $WeaponManager

func _ready() -> void:
	current_health = max_health
	add_to_group("player")
	health_changed.emit(current_health, max_health)

	# Add starting weapon
	weapon_manager.add_weapon_by_name("Rusty Pistol")

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	_handle_input()
	_handle_movement(delta)

# Public methods
func take_damage(amount: int) -> void:
	if not is_alive:
		return

	current_health -= amount
	current_health = max(0, current_health)
	health_changed.emit(current_health, max_health)

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
	if _input_direction != Vector2.ZERO:
		# Normalize for consistent diagonal speed
		var move_direction := _input_direction.normalized()
		velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)
	else:
		# Apply friction when not moving
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()
