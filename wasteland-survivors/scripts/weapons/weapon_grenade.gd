class_name WeaponGrenade
extends WeaponProjectile

## Grenade Launcher weapon - fires arcing projectiles that explode on impact for AoE damage.
## Explosion Radius increases blast size. Can pierce before exploding.

# Grenade specific
@export var explosion_radius: float = 60.0
@export var arc_height: float = 100.0

var explosion_radius_multiplier: float = 1.0

# Grenade scene
const GRENADE_SCENE := preload("res://scenes/weapons/grenade_projectile.tscn")

# Computed properties
var effective_explosion_radius: float:
	get: return explosion_radius * explosion_radius_multiplier

func _ready() -> void:
	# Set weapon properties
	weapon_name = "Grenade Launcher"
	base_damage = 25.0  # High damage but slow
	base_fire_rate = 0.8  # Less than 1 shot per second
	projectile_speed = 250.0  # Slower projectiles
	projectile_count = 1
	base_weapon_range = 350.0
	pierce_count = 0  # Can pierce before exploding
	projectile_spread_angle = 0.0
	multi_shot_delay = 0.2

	super._ready()
	print("WeaponGrenade: Initialized with grenade scene")

func _spawn_projectile(base_direction: Vector2, index: int) -> void:
	"""Spawn grenade projectile using scene."""
	var target: Node2D = _find_target_in_direction(base_direction)
	if not NodeUtils.is_valid(target):
		return

	# Instantiate grenade from scene
	var grenade: GrenadeProjectile = GRENADE_SCENE.instantiate()

	# Get positions
	var start_pos: Vector2 = get_owner_position()
	var target_pos: Vector2 = target.global_position

	# Configure grenade
	grenade.configure(damage, projectile_speed, start_pos, target_pos, arc_height, effective_explosion_radius, pierce_count + pierce_bonus)

	# Add to scene
	get_tree().current_scene.call_deferred("add_child", grenade)

	print("WeaponGrenade: Spawned grenade at ", start_pos, " targeting ", target_pos)

func _find_target_in_direction(direction: Vector2) -> Node2D:
	"""Find target enemy for grenade."""
	return get_nearest_enemy()

func _apply_custom_upgrade(stat_name: String, multiplier: float) -> void:
	match stat_name:
		"Explosion Radius":
			explosion_radius_multiplier *= multiplier
		_:
			super._apply_custom_upgrade(stat_name, multiplier)
