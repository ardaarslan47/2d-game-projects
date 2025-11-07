class_name WeaponBaseNew
extends Node2D

## Abstract base class for all weapons.
## Handles cooldowns, upgrades, and core weapon logic.
## Subclasses override _execute_fire() to implement specific weapon behavior.

# Signals
signal fired

# Base exported variables (all weapons)
@export var weapon_name: String = "Weapon"
@export var base_damage: float = 10.0
@export var base_fire_rate: float = 1.0  # Shots/activations per second
@export var base_weapon_range: float = 300.0  # Maximum range

# Public variables
var owner_node: Node2D  # Set by WeaponManager when weapon is added

# Upgrade multipliers (applied to base stats)
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var range_multiplier: float = 1.0

# Computed properties
var damage: float:
	get: return base_damage * damage_multiplier

var fire_rate: float:
	get: return base_fire_rate * fire_rate_multiplier

var weapon_range: float:
	get: return base_weapon_range * range_multiplier

# Private variables
var _fire_cooldown: float = 0.0
var _can_fire: bool = true

func _ready() -> void:
	assert(owner_node != null, "WeaponBaseNew: owner_node must be set by WeaponManager before _ready()")
	_on_weapon_ready()

func _process(delta: float) -> void:
	# Keep weapon positioned at owner (player) position
	if owner_node:
		global_position = owner_node.global_position

	# Handle fire cooldown
	if _fire_cooldown > 0:
		_fire_cooldown -= delta
		if _fire_cooldown <= 0:
			_can_fire = true

	# Process weapon-specific logic
	_process_weapon(delta)

	# Auto-fire if can fire
	if _can_fire:
		fire()

## Public Methods

func fire() -> void:
	"""Attempts to fire the weapon. Calls _execute_fire() if ready."""
	if not _can_fire:
		return

	_can_fire = false
	_fire_cooldown = 1.0 / fire_rate

	_execute_fire()
	fired.emit()

## Upgrade Methods (can be overridden for custom behavior)

func upgrade_stat(stat_name: String, multiplier: float) -> void:
	"""Apply an upgrade to a weapon stat. Override for weapon-specific stats."""
	match stat_name:
		"Damage":
			damage_multiplier *= multiplier
		"Fire Rate":
			fire_rate_multiplier *= multiplier
		"Range":
			range_multiplier *= multiplier
		_:
			_apply_custom_upgrade(stat_name, multiplier)

## Virtual Methods (override in subclasses)

func _on_weapon_ready() -> void:
	"""Called when weapon is ready. Override for weapon-specific initialization."""
	pass

func _process_weapon(_delta: float) -> void:
	"""Called every frame. Override for continuous weapon logic (e.g., beam weapons)."""
	pass

func _execute_fire() -> void:
	"""Execute the weapon's firing logic. Must be overridden by subclasses."""
	push_error("WeaponBaseNew._execute_fire() must be overridden by subclass: " + weapon_name)

func _apply_custom_upgrade(_stat_name: String, _multiplier: float) -> void:
	"""Apply weapon-specific upgrade stats. Override for custom stats."""
	push_warning("WeaponBaseNew: Unknown upgrade stat '" + _stat_name + "' for " + weapon_name)

## Utility Methods

func get_owner_position() -> Vector2:
	"""Get the owner's global position."""
	return owner_node.global_position if owner_node else global_position

func get_enemies_in_range() -> Array[Node]:
	"""Get all valid enemies within weapon range."""
	var all_enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	var enemies_in_range: Array[Node] = []
	var owner_pos: Vector2 = get_owner_position()

	for enemy in all_enemies:
		if owner_pos.distance_to(enemy.global_position) <= weapon_range:
			enemies_in_range.append(enemy)

	return enemies_in_range

func get_nearest_enemy() -> Node:
	"""Get the nearest valid enemy, or null if none exist."""
	var enemies: Array[Node] = NodeUtils.get_valid_nodes_in_group(get_tree(), "enemies")
	if enemies.is_empty():
		return null

	var owner_pos: Vector2 = get_owner_position()
	var nearest: Node = null
	var nearest_dist: float = INF

	for enemy in enemies:
		var dist: float = owner_pos.distance_to(enemy.global_position)
		if dist < nearest_dist and dist <= weapon_range:
			nearest = enemy
			nearest_dist = dist

	return nearest
