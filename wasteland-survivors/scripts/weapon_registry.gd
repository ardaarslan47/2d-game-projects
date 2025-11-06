class_name WeaponRegistry
extends Resource

## Registry for all available weapons in the game.
## Allows dynamic weapon registration without code changes.

# Map of weapon names to script paths
@export var weapons: Dictionary = {
	"Rusty Pistol": "res://scripts/weapons/weapon_pistol.gd"
}

## Get weapon script by name.
func get_weapon_script(weapon_name: String) -> Script:
	if weapon_name in weapons:
		return load(weapons[weapon_name])
	push_error("WeaponRegistry: Weapon '%s' not found in registry" % weapon_name)
	return null

## Register a new weapon dynamically (useful for mods/expansions).
func register_weapon(weapon_name: String, script_path: String) -> void:
	weapons[weapon_name] = script_path

## Get all registered weapon names.
func get_all_weapons() -> Array[String]:
	var result: Array[String] = []
	for weapon_name in weapons.keys():
		result.append(weapon_name)
	return result

## Check if a weapon is registered.
func has_weapon(weapon_name: String) -> bool:
	return weapon_name in weapons
