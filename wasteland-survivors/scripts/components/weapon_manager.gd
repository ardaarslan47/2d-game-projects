class_name WeaponManager
extends Node

## Manages multiple active weapons for the player.
## Handles weapon addition, removal, and updates.

# Signals
signal weapon_added(weapon: WeaponBase)
signal weapon_removed(weapon: WeaponBase)

# Public variables
var active_weapons: Array[WeaponBase] = []

# Public methods
func add_weapon(weapon_script: Script) -> WeaponBase:
	var weapon: WeaponBase = weapon_script.new()
	add_child(weapon)
	active_weapons.append(weapon)
	weapon_added.emit(weapon)
	return weapon

func add_weapon_by_name(weapon_name: String) -> WeaponBase:
	var weapon_script: Script = _get_weapon_script(weapon_name)
	if weapon_script:
		return add_weapon(weapon_script)
	return null

func remove_weapon(weapon: WeaponBase) -> void:
	if weapon in active_weapons:
		active_weapons.erase(weapon)
		weapon_removed.emit(weapon)
		weapon.queue_free()

func has_weapon(weapon_name: String) -> bool:
	for weapon in active_weapons:
		if weapon.weapon_name == weapon_name:
			return true
	return false

func get_weapon(weapon_name: String) -> WeaponBase:
	for weapon in active_weapons:
		if weapon.weapon_name == weapon_name:
			return weapon
	return null

# Private methods
func _get_weapon_script(weapon_name: String) -> Script:
	match weapon_name:
		"Rusty Pistol":
			return load("res://scripts/weapons/weapon_pistol.gd")
		_:
			return null
