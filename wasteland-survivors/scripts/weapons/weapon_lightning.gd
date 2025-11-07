class_name WeaponLightning
extends WeaponBaseNew

## Chain Lightning weapon - bolt jumps between multiple enemies.
## Jump Count determines how many enemies the bolt hits. Chain Range affects jump distance.

# Lightning specific
@export var max_jumps: int = 3
@export var chain_range: float = 150.0

var jump_count_bonus: int = 0
var chain_range_multiplier: float = 1.0

# Lightning bolt scene
const BOLT_SCENE := preload("res://scenes/weapons/lightning_bolt.tscn")

# Computed properties
var total_jumps: int:
	get: return max_jumps + jump_count_bonus

var effective_chain_range: float:
	get: return chain_range * chain_range_multiplier

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Chain Lightning"
	base_damage = 14.0
	base_fire_rate = 1.2
	base_weapon_range = 300.0

	super._ready()
	print("WeaponLightning: Initialized with lightning bolt scene")

func _execute_fire() -> void:
	"""Fire lightning bolt that chains between enemies."""
	var start_pos: Vector2 = get_owner_position()

	# Find first target
	var first_target: Node = get_nearest_enemy()
	if not first_target:
		return

	# Create chain
	var chain: Array[Node] = [first_target]
	var current_target: Node = first_target

	# Find subsequent targets
	for i in range(total_jumps - 1):
		var next_target: Node = _find_next_chain_target(current_target, chain)
		if next_target:
			chain.append(next_target)
			current_target = next_target
		else:
			break

	# Create lightning bolt visual and damage enemies
	var positions: Array[Vector2] = [start_pos]
	for enemy in chain:
		positions.append(enemy.global_position)
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

	# Instantiate lightning bolt from scene
	var bolt: LightningBolt = BOLT_SCENE.instantiate()
	bolt.configure(damage, positions)
	get_tree().current_scene.call_deferred("add_child", bolt)

	print("WeaponLightning: Created lightning chain with ", chain.size(), " jumps")

func _find_next_chain_target(from_enemy: Node, already_hit: Array) -> Node:
	"""Find the next enemy in chain range that hasn't been hit."""
	var enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	var from_pos: Vector2 = from_enemy.global_position

	var nearest: Node = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if enemy in already_hit:
			continue

		var dist: float = from_pos.distance_to(enemy.global_position)
		if dist <= effective_chain_range and dist < nearest_dist:
			nearest = enemy
			nearest_dist = dist

	return nearest

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Jump Count":
			jump_count_bonus += int(multiplier)
		"Chain Range":
			chain_range_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
