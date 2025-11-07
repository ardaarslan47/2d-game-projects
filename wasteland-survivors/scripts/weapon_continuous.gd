class_name WeaponContinuous
extends WeaponBaseNew

## Base class for continuous/always-active weapons.
## These weapons don't fire on cooldown but continuously process and deal damage.
## Examples: Aura, Orbital, Beam weapons

# Continuous weapon exports
@export var damage_interval: float = 0.5  # Time between damage ticks
@export var area_size: float = 100.0  # Base size of effect area
@export var continuous_visual: Node2D  # Visual effect node (set in child scenes)

# Upgrade bonuses
var area_size_multiplier: float = 1.0

# Computed properties
var effective_area_size: float:
	get: return area_size * area_size_multiplier

var effective_damage_interval: float:
	get: return damage_interval / fire_rate_multiplier  # Faster fire rate = more frequent damage

# Private variables
var _damage_timer: float = 0.0
var _tracked_enemies: Dictionary = {}  # enemy: time_since_last_hit

func _on_weapon_ready() -> void:
	# Continuous weapons don't use standard firing
	_can_fire = false
	_fire_cooldown = INF  # Disable cooldown system

func _process_weapon(delta: float) -> void:
	# Update damage timer
	_damage_timer += delta

	# Check if we should deal damage
	if _damage_timer >= effective_damage_interval:
		_apply_continuous_damage()
		_damage_timer = 0.0

	# Update visual effect
	_update_visual_effect(delta)

func _execute_fire() -> void:
	# Continuous weapons don't use the fire system
	pass

## Virtual Methods (override in subclasses)

func _apply_continuous_damage() -> void:
	"""Apply damage to enemies in range. Override for weapon-specific behavior."""
	push_error("WeaponContinuous._apply_continuous_damage() must be overridden by subclass: " + weapon_name)

func _update_visual_effect(_delta: float) -> void:
	"""Update weapon's visual effect. Override for custom visuals."""
	pass

## Utility Methods

func damage_enemy(enemy: Node) -> void:
	"""Deal damage to a single enemy."""
	if not enemy:
		return

	# Always call enemy.take_damage() to trigger hit visual feedback
	if enemy.has_method("take_damage"):
		enemy.take_damage(int(damage))

func damage_enemies_in_area(center: Vector2, radius: float) -> int:
	"""Damage all enemies within a circular area. Returns number of enemies hit."""
	var enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	var hit_count: int = 0

	for enemy in enemies:
		var distance: float = center.distance_to(enemy.global_position)
		if distance <= radius:
			damage_enemy(enemy)
			hit_count += 1

	return hit_count

func get_enemies_in_circle(center: Vector2, radius: float) -> Array[Node]:
	"""Get all enemies within a circular area."""
	var all_enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	var enemies_in_circle: Array[Node] = []

	for enemy in all_enemies:
		if center.distance_to(enemy.global_position) <= radius:
			enemies_in_circle.append(enemy)

	return enemies_in_circle

## Override upgrade method for continuous weapon stats

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Size":
			area_size_multiplier *= multiplier
		"Area Size":
			area_size_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
