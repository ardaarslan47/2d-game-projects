class_name CharacterData
extends Resource

## Defines a playable character with their starting configuration and passive abilities.

@export var character_name: String = ""
@export var character_color: Color = Color.WHITE
@export var starting_weapon: String = ""
@export var passive_description: String = ""
@export var xp_bonus_multiplier: float = 0.1  # +10% XP by default

func _init(
	p_name: String = "",
	p_color: Color = Color.WHITE,
	p_weapon: String = "",
	p_passive: String = "",
	p_xp_bonus: float = 0.1
) -> void:
	character_name = p_name
	character_color = p_color
	starting_weapon = p_weapon
	passive_description = p_passive
	xp_bonus_multiplier = p_xp_bonus
