class_name HealthComponent
extends Node

## Reusable health component for any entity (player, enemies, etc.)
## Handles health, damage, healing, and death.

# Signals
signal health_changed(current: int, maximum: int)
signal damage_taken(amount: int)
signal healed(amount: int)
signal died

# Exported variables
@export var max_health: int = 100
@export var start_at_max: bool = true

# Public variables
var current_health: int = 0
var is_alive: bool = true

func _ready() -> void:
	if start_at_max:
		current_health = max_health
	health_changed.emit(current_health, max_health)

# Public methods
func take_damage(amount: int) -> void:
	if not is_alive or amount <= 0:
		return

	var damage_dealt: int = min(amount, current_health)
	current_health -= damage_dealt

	damage_taken.emit(damage_dealt)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	if not is_alive or amount <= 0:
		return

	var old_health: int = current_health
	current_health = min(current_health + amount, max_health)

	var healed_amount: int = current_health - old_health
	if healed_amount > 0:
		healed.emit(healed_amount)
		health_changed.emit(current_health, max_health)

func set_max_health(new_max: int) -> void:
	max_health = max(1, new_max)
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func die() -> void:
	if not is_alive:
		return

	is_alive = false
	died.emit()
