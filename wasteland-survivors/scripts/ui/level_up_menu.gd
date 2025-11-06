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
	CONE_ANGLE  # Sword-specific: increases slash cone width
}

# Upgrade stat display names and ranges
const STAT_INFO: Dictionary = {
	UpgradeStat.DAMAGE: {"name": "Damage", "min": 10, "max": 25, "suffix": "%"},
	UpgradeStat.FIRE_RATE: {"name": "Attack Speed", "min": 5, "max": 20, "suffix": "%"},
	UpgradeStat.RANGE: {"name": "Range", "min": 10, "max": 30, "suffix": "%"},
	UpgradeStat.PIERCE: {"name": "Penetration", "min": 1, "max": 2, "suffix": ""},
	UpgradeStat.PROJECTILE_COUNT: {"name": "Multi-Shot", "min": 1, "max": 1, "suffix": ""},
	UpgradeStat.PROJECTILE_SIZE: {"name": "Projectile Size", "min": 10, "max": 25, "suffix": "%"},
	UpgradeStat.CONE_ANGLE: {"name": "Cone Width", "min": 5, "max": 15, "suffix": "°"}
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

## Generate 3 random upgrade options, each with 2 random stats.
## Selects weapons from player's active weapons and appropriate stats for each.
func _generate_upgrade_options() -> void:
	_upgrade_options.clear()

	# Get player's active weapons
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player or not player.weapon_manager:
		push_error("LevelUpMenu: Cannot find player or weapon_manager")
		return

	var active_weapons: Array[WeaponBase] = player.weapon_manager.active_weapons
	if active_weapons.is_empty():
		push_error("LevelUpMenu: Player has no active weapons")
		return

	for i in range(3):
		# Pick a random weapon from active weapons
		var weapon: WeaponBase = active_weapons[randi() % active_weapons.size()]
		var weapon_name: String = weapon.weapon_name

		var upgrade: Dictionary = {
			"weapon": weapon_name,
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

## Update button texts to show the generated upgrade options.
func _update_button_texts() -> void:
	var buttons: Array[Button] = [button_1, button_2, button_3]

	for i in range(3):
		if i < _upgrade_options.size():
			var upgrade: Dictionary = _upgrade_options[i]
			var text: String = upgrade.weapon + "\n"

			for stat in upgrade.stats:
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
