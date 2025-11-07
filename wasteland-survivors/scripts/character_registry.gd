extends Node

## Central registry for all playable characters in the game.
## Provides access to character definitions and selected character data.

var characters: Array[CharacterData] = []
var selected_character: CharacterData = null

func _init() -> void:
	_initialize_characters()

func _initialize_characters() -> void:
	characters = [
		CharacterData.new(
			"The Gunslinger",
			Color(0.9, 0.3, 0.2),  # Red/Orange
			"Rusty Pistol",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Warrior",
			Color(0.3, 0.5, 0.7),  # Steel Blue
			"Rusty Sword",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Mystic",
			Color(0.6, 0.2, 0.8),  # Purple
			"Purple Aura",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Soldier",
			Color(0.5, 0.6, 0.3),  # Olive Green
			"Machine Gun",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Engineer",
			Color(0.9, 0.8, 0.2),  # Yellow/Gold
			"Orbital Satellites",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Guardian",
			Color(0.2, 0.8, 0.9),  # Cyan
			"Force Field",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Scientist",
			Color(0.9, 0.9, 0.95),  # White/Silver
			"Laser Beam",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Demolitionist",
			Color(0.6, 0.2, 0.15),  # Dark Red/Brown
			"Grenade Launcher",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Stormbringer",
			Color(0.1, 0.4, 0.9),  # Electric Blue
			"Chain Lightning",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Hunter",
			Color(0.2, 0.5, 0.3),  # Dark Green
			"Homing Missiles",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Duelist",
			Color(0.8, 0.1, 0.5),  # Magenta/Pink
			"Rusty Sword",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Sharpshooter",
			Color(0.4, 0.3, 0.2),  # Brown
			"Rusty Pistol",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Reaper",
			Color(0.2, 0.2, 0.2),  # Dark Gray/Black
			"Purple Aura",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Commando",
			Color(0.1, 0.6, 0.2),  # Bright Green
			"Machine Gun",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
		CharacterData.new(
			"The Technomancer",
			Color(0.9, 0.4, 0.1),  # Orange
			"Orbital Satellites",
			"+10% XP per level (Level 2: +10%, Level 11: +100%)",
			0.1
		),
	]

func get_character_count() -> int:
	return characters.size()

func get_character_at_index(index: int) -> CharacterData:
	if index >= 0 and index < characters.size():
		return characters[index]
	return null

func set_selected_character(character: CharacterData) -> void:
	selected_character = character

func get_selected_character() -> CharacterData:
	return selected_character
