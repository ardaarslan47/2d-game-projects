class_name EnemySpawner
extends Node2D

## Spawns enemies in waves around the player.
## Simple implementation for Phase 1.

# Exported variables
@export var spawn_interval: float = 1.0
@export var spawn_distance: float = 600.0
@export var max_enemies: int = 50

# Private variables
var _spawn_timer: float = 0.0
var _zombie_scene: PackedScene

# Onready variables
@onready var player: Node2D = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	_zombie_scene = load("res://scenes/enemies/zombie.tscn")

func _process(delta: float) -> void:
	_spawn_timer -= delta

	if _spawn_timer <= 0:
		_spawn_timer = spawn_interval
		_spawn_enemy()

# Private methods
func _spawn_enemy() -> void:
	# Check enemy limit
	var current_enemies := get_tree().get_nodes_in_group("enemies")
	if current_enemies.size() >= max_enemies:
		return

	if not player or not is_instance_valid(player):
		return

	# Spawn zombie at random position around player
	var angle := randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * spawn_distance
	var spawn_pos := player.global_position + offset

	var zombie: EnemyBase = _zombie_scene.instantiate()
	get_parent().add_child(zombie)
	zombie.global_position = spawn_pos
