class_name LevelUpMenu
extends CanvasLayer

## Level-up menu that pauses the game and offers upgrade choices.

# Signals
signal upgrade_selected(upgrade_data: Dictionary)

# Available upgrade stats
enum UpgradeStat {
	DAMAGE,
	FIRE_RATE,
	RANGE,
	PIERCE,
	PROJECTILE_COUNT,
	PROJECTILE_SIZE,
	CONE_ANGLE,  # Sword-specific: increases slash cone width
	AREA_SIZE,  # Aura, Force Field: increases area radius
	SATELLITE_COUNT,  # Orbital: adds more satellites
	ORBIT_SPEED,  # Orbital: rotation speed
	PUSH_FORCE,  # Force Field: knockback strength
	BEAM_WIDTH,  # Laser: beam thickness
	SWEEP_SPEED,  # Laser: target tracking speed
	EXPLOSION_RADIUS,  # Grenade: blast radius
	JUMP_COUNT,  # Chain Lightning: number of enemy jumps
	CHAIN_RANGE,  # Chain Lightning: jump distance
	HOMING_STRENGTH,  # Homing Missiles: turning speed
	PROJECTILE_SPEED,  # Machine Gun, Missiles: projectile velocity
	SPREAD_ANGLE  # Machine Gun: multi-shot spread
}

# Upgrade stat display names and ranges
const STAT_INFO: Dictionary = {
	UpgradeStat.DAMAGE: {"name": "Damage", "min": 10, "max": 25, "suffix": "%"},
	UpgradeStat.FIRE_RATE: {"name": "Attack Speed", "min": 5, "max": 20, "suffix": "%"},
	UpgradeStat.RANGE: {"name": "Range", "min": 10, "max": 30, "suffix": "%"},
	UpgradeStat.PIERCE: {"name": "Penetration", "min": 1, "max": 2, "suffix": ""},
	UpgradeStat.PROJECTILE_COUNT: {"name": "Multi-Shot", "min": 1, "max": 1, "suffix": ""},
	UpgradeStat.PROJECTILE_SIZE: {"name": "Projectile Size", "min": 10, "max": 25, "suffix": "%"},
	UpgradeStat.CONE_ANGLE: {"name": "Cone Width", "min": 5, "max": 15, "suffix": "°"},
	UpgradeStat.AREA_SIZE: {"name": "Size", "min": 10, "max": 30, "suffix": "%"},
	UpgradeStat.SATELLITE_COUNT: {"name": "Satellite Count", "min": 1, "max": 1, "suffix": ""},
	UpgradeStat.ORBIT_SPEED: {"name": "Orbit Speed", "min": 10, "max": 25, "suffix": "%"},
	UpgradeStat.PUSH_FORCE: {"name": "Push Force", "min": 15, "max": 35, "suffix": "%"},
	UpgradeStat.BEAM_WIDTH: {"name": "Beam Width", "min": 10, "max": 30, "suffix": "%"},
	UpgradeStat.SWEEP_SPEED: {"name": "Sweep Speed", "min": 15, "max": 30, "suffix": "%"},
	UpgradeStat.EXPLOSION_RADIUS: {"name": "Blast Radius", "min": 15, "max": 35, "suffix": "%"},
	UpgradeStat.JUMP_COUNT: {"name": "Chain Jumps", "min": 1, "max": 2, "suffix": ""},
	UpgradeStat.CHAIN_RANGE: {"name": "Chain Range", "min": 10, "max": 30, "suffix": "%"},
	UpgradeStat.HOMING_STRENGTH: {"name": "Homing Power", "min": 15, "max": 35, "suffix": "%"},
	UpgradeStat.PROJECTILE_SPEED: {"name": "Projectile Speed", "min": 10, "max": 25, "suffix": "%"},
	UpgradeStat.SPREAD_ANGLE: {"name": "Spread", "min": 5, "max": 15, "suffix": "°"}
}

# Weapon-specific stat compatibility
const WEAPON_STATS: Dictionary = {
	"Rusty Pistol": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.PIERCE,
		UpgradeStat.PROJECTILE_COUNT,
		UpgradeStat.PROJECTILE_SIZE
	],
	"Rusty Sword": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.CONE_ANGLE,
		UpgradeStat.PROJECTILE_COUNT
	],
	"Purple Aura": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.AREA_SIZE  # Size increases radius, no multi-shot
	],
	"Machine Gun": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.PROJECTILE_COUNT,  # Multi-shot fires simultaneously with spread
		UpgradeStat.PROJECTILE_SPEED,
		UpgradeStat.PROJECTILE_SIZE
	],
	"Orbital Satellites": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.SATELLITE_COUNT,  # Adds more orbitals
		UpgradeStat.ORBIT_SPEED
	],
	"Force Field": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.AREA_SIZE,
		UpgradeStat.PUSH_FORCE
	],
	"Laser Beam": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.BEAM_WIDTH,
		UpgradeStat.SWEEP_SPEED
	],
	"Grenade Launcher": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.PIERCE,  # Can pierce before exploding
		UpgradeStat.PROJECTILE_COUNT,
		UpgradeStat.EXPLOSION_RADIUS
	],
	"Chain Lightning": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.JUMP_COUNT,  # Number of enemy jumps
		UpgradeStat.CHAIN_RANGE  # Jump distance
	],
	"Homing Missiles": [
		UpgradeStat.DAMAGE,
		UpgradeStat.FIRE_RATE,
		UpgradeStat.RANGE,
		UpgradeStat.PIERCE,
		UpgradeStat.PROJECTILE_COUNT,
		UpgradeStat.HOMING_STRENGTH,
		UpgradeStat.PROJECTILE_SPEED
	]
}

# Private variables
var _upgrade_options: Array[Dictionary] = []

# Onready variables
@onready var button_1: Button = $CenterContainer/PanelContainer/VBoxContainer/UpgradeContainer/AttackSpeedButton
@onready var button_2: Button = $CenterContainer/PanelContainer/VBoxContainer/UpgradeContainer/DamageButton
@onready var button_3: Button = $CenterContainer/PanelContainer/VBoxContainer/UpgradeContainer/PenetrationButton

func _ready() -> void:
	hide()

	# Connect hover effects to buttons
	_setup_button_hover_effects(button_1)
	_setup_button_hover_effects(button_2)
	_setup_button_hover_effects(button_3)

## Show the level-up menu and pause the game.
func show_menu() -> void:
	_generate_upgrade_options()
	_update_button_texts()
	show()
	get_tree().paused = true

## Hide the level-up menu and unpause the game.
func hide_menu() -> void:
	hide()
	get_tree().paused = false

## Generate 3 random upgrade options.
## Each option is either:
## - An upgrade for an unlocked weapon (2 random stats)
## - An unlock option for a locked weapon (no stats)
## All weapons have equal probability of being selected.
func _generate_upgrade_options() -> void:
	_upgrade_options.clear()

	# Get player and weapon manager
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player or not player.weapon_manager:
		push_error("LevelUpMenu: Cannot find player or weapon_manager")
		return

	# Get all available weapon names from registry
	var weapon_registry: WeaponRegistry = player.weapon_manager.weapon_registry
	if not weapon_registry:
		push_error("LevelUpMenu: No weapon registry found")
		return

	var all_weapon_names: Array[String] = weapon_registry.get_all_weapons()
	if all_weapon_names.is_empty():
		push_error("LevelUpMenu: No weapons in registry")
		return

	# Check weapon cap (max 3 weapons)
	const MAX_WEAPONS: int = 3
	var current_weapon_count: int = player.weapon_manager.active_weapons.size()
	var at_weapon_cap: bool = current_weapon_count >= MAX_WEAPONS

	if at_weapon_cap:
		print("At weapon cap (%d/%d) - only showing upgrades" % [current_weapon_count, MAX_WEAPONS])

	# Create pool of available weapons (locked + unlocked)
	# If at cap, only include unlocked weapons
	var available_pool: Array[String] = []
	for weapon_name in all_weapon_names:
		var is_unlocked: bool = player.weapon_manager.has_weapon(weapon_name)
		if at_weapon_cap:
			# Only add unlocked weapons when at cap
			if is_unlocked:
				available_pool.append(weapon_name)
		else:
			# Add all weapons when below cap
			available_pool.append(weapon_name)

	if available_pool.is_empty():
		push_error("LevelUpMenu: No weapons available for selection")
		return

	# Shuffle and pick unique weapons for each option
	available_pool.shuffle()
	var selected_weapons: Array[String] = []

	# Generate 3 unique options
	for i in range(3):
		# Pick a weapon not yet selected
		var weapon_name: String = ""
		for candidate in available_pool:
			if candidate not in selected_weapons:
				weapon_name = candidate
				selected_weapons.append(weapon_name)
				break

		# Fallback if we run out of unique weapons (shouldn't happen with 10 weapons)
		if weapon_name == "":
			weapon_name = available_pool[randi() % available_pool.size()]

		# Check if player has this weapon
		var is_unlocked: bool = player.weapon_manager.has_weapon(weapon_name)
		print("Level-up option %d: %s (unlocked: %s)" % [i + 1, weapon_name, is_unlocked])

		if is_unlocked:
			# Generate upgrade option with 2 stats
			var upgrade: Dictionary = {
				"weapon": weapon_name,
				"is_unlock": false,
				"stats": []
			}

			# Get available stats for this weapon (duplicate to avoid read-only error)
			var available_stats: Array = WEAPON_STATS.get(weapon_name, STAT_INFO.keys()).duplicate()
			available_stats.shuffle()

			# Pick 2 random, unique stats for this weapon
			for j in range(min(2, available_stats.size())):
				var stat_type: UpgradeStat = available_stats[j]
				var stat_info: Dictionary = STAT_INFO[stat_type]

				var value: int = randi_range(stat_info.min, stat_info.max)

				upgrade.stats.append({
					"type": stat_type,
					"name": stat_info.name,
					"value": value,
					"suffix": stat_info.suffix
				})

			_upgrade_options.append(upgrade)
			print("  → Generated upgrade with %d stats" % upgrade.stats.size())
		else:
			# Generate unlock option (no stats)
			var unlock: Dictionary = {
				"weapon": weapon_name,
				"is_unlock": true,
				"stats": []
			}
			_upgrade_options.append(unlock)
			print("  → Generated UNLOCK option")

## Update button texts to show the generated upgrade options.
## Shows "UNLOCK [Weapon]" for locked weapons, or stat details for upgrades.
func _update_button_texts() -> void:
	var buttons: Array[Button] = [button_1, button_2, button_3]

	for i in range(3):
		if i < _upgrade_options.size():
			var option: Dictionary = _upgrade_options[i]
			var text: String = ""

			if option.is_unlock:
				# Show unlock text for locked weapons
				text = "UNLOCK\n" + option.weapon
			else:
				# Show weapon name and stat upgrades
				text = option.weapon + "\n"
				for stat in option.stats:
					text += "+%d%s %s  " % [stat.value, stat.suffix, stat.name]

			buttons[i].text = text.strip_edges()

func _on_attack_speed_button_pressed() -> void:
	if _upgrade_options.size() > 0:
		upgrade_selected.emit(_upgrade_options[0])
	hide_menu()

func _on_damage_button_pressed() -> void:
	if _upgrade_options.size() > 1:
		upgrade_selected.emit(_upgrade_options[1])
	hide_menu()

func _on_penetration_button_pressed() -> void:
	if _upgrade_options.size() > 2:
		upgrade_selected.emit(_upgrade_options[2])
	hide_menu()

func _setup_button_hover_effects(button: Button) -> void:
	"""Add hover effects to a button - brighten on hover, normal on exit."""
	button.mouse_entered.connect(func(): button.modulate = Color(1.2, 1.2, 1.2))
	button.mouse_exited.connect(func(): button.modulate = Color(1.0, 1.0, 1.0))
