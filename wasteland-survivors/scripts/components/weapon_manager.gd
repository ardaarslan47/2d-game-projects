class_name WeaponManager
extends Node

## Manages multiple active weapons for the player.
## Handles weapon addition, removal, and updates.

# Signals
signal weapon_added(weapon: Node)
signal weapon_removed(weapon: Node)

# Exported variables
@export var weapon_registry: WeaponRegistry
@export var projectile_pool: ProjectilePool  # Optional: Set to use object pooling for all weapons

# Public variables
var active_weapons: Array[Node] = []  # Can hold both WeaponBase and WeaponBaseNew

func _ready() -> void:
	# Create default registry if not set
	if not weapon_registry:
		weapon_registry = WeaponRegistry.new()

# Public methods
func add_weapon(weapon_script: Script) -> WeaponBaseNew:
	var weapon: WeaponBaseNew = weapon_script.new()
	# Set owner_node before adding to tree (before _ready() is called)
	weapon.owner_node = get_parent()
	# Set projectile pool if available
	if projectile_pool:
		weapon.projectile_pool = projectile_pool
	add_child(weapon)
	active_weapons.append(weapon)
	weapon_added.emit(weapon)
	return weapon

func add_weapon_by_name(weapon_name: String) -> WeaponBaseNew:
	var weapon_script: Script = _get_weapon_script(weapon_name)
	if weapon_script:
		return add_weapon(weapon_script)
	return null

func remove_weapon(weapon: Node) -> void:
	if weapon in active_weapons:
		active_weapons.erase(weapon)
		weapon_removed.emit(weapon)
		weapon.queue_free()

func has_weapon(weapon_name: String) -> bool:
	for weapon in active_weapons:
		if "weapon_name" in weapon and weapon.weapon_name == weapon_name:
			return true
	return false

func get_weapon(weapon_name: String) -> Node:
	for weapon in active_weapons:
		if "weapon_name" in weapon and weapon.weapon_name == weapon_name:
			return weapon
	return null

func get_active_weapons() -> Array[Node]:
	return active_weapons

# Private methods
func _get_weapon_script(weapon_name: String) -> Script:
	return weapon_registry.get_weapon_script(weapon_name)
