class_name Projectile
extends Area2D

## Base projectile class for all weapon projectiles.
## Handles movement, collision, damage, and lifetime.

# Exported variables
@export var speed: float = 400.0
@export var damage: int = 10
@export var lifetime: float = 3.0
@export var pierce_count: int = 0

# Public variables
var direction: Vector2 = Vector2.RIGHT
var traveled_distance: float = 0.0
var max_distance: float = 1000.0

# Private variables
var _pierced_enemies: int = 0
var _hit_enemies: Array[Node] = []

# Onready variables
@onready var sprite: ColorRect = $Sprite
@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
	# Start lifetime timer
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	lifetime_timer.start()

	# Connect both collision signals for maximum compatibility
	# Area2D projectile can collide with enemy Area2D (Hitbox) or CharacterBody2D
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Move projectile
	var movement: Vector2 = direction * speed * delta
	position += movement
	traveled_distance += movement.length()

	# Check max distance
	if traveled_distance >= max_distance:
		queue_free()

# Public methods
func setup(start_pos: Vector2, dir: Vector2, dmg: int = 10) -> void:
	global_position = start_pos
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()

# Private methods
func _on_area_entered(area: Area2D) -> void:
	# Enemy hitbox is Area2D child of CharacterBody2D enemy
	var parent := area.get_parent()
	if parent and parent.is_in_group("enemies"):
		_hit_enemy(parent)

func _on_body_entered(body: Node2D) -> void:
	# Direct collision with enemy CharacterBody2D
	if body.is_in_group("enemies"):
		_hit_enemy(body)

func _hit_enemy(enemy: Node) -> void:
	# Prevent hitting the same enemy multiple times
	if enemy in _hit_enemies:
		return

	_hit_enemies.append(enemy)

	# Deal damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Check pierce count
	_pierced_enemies += 1
	if _pierced_enemies > pierce_count:
		queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
