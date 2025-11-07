class_name WeaponAura
extends WeaponContinuous

## Aura weapon - continuous damage in a circle around the player.
## Hits enemies that enter its range repeatedly based on attack speed.
## Size upgrade increases radius.

# Aura scene instance
const AURA_SCENE := preload("res://scenes/weapons/aura_effect.tscn")
var _aura_effect: AuraEffect = null

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Purple Aura"
	base_damage = 8.0
	base_fire_rate = 2.0  # 2 hits per second
	area_size = 80.0  # Base radius
	base_weapon_range = 80.0
	damage_interval = 0.5  # Hit every 0.5 seconds at base fire rate

	super._ready()
	_create_aura()
	print("WeaponAura: Initialized with aura effect scene")

func _create_aura() -> void:
	"""Instantiate aura effect from scene."""
	_aura_effect = AURA_SCENE.instantiate()
	add_child(_aura_effect)

	# Configure aura properties
	var tick_rate := damage_interval
	_aura_effect.configure(damage, effective_area_size, tick_rate)

	print("WeaponAura: Created aura with damage=", damage, " radius=", effective_area_size)

func _process_weapon(delta: float) -> void:
	# Update aura configuration if properties changed
	if _aura_effect:
		_aura_effect.damage_per_tick = damage
		_aura_effect.set_radius(effective_area_size)

	# Call parent for damage timing
	super._process_weapon(delta)

func _apply_continuous_damage() -> void:
	"""Damage is handled by the aura effect scene itself."""
	# The AuraEffect node handles its own damage ticks
	fired.emit()

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Size":
			area_size_multiplier *= multiplier
			base_weapon_range *= multiplier  # Range also increases with size
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
