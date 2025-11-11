class_name DamagePopup
extends Node2D

## Displays a floating damage number that fades and moves upward.

@export var damage_amount: int = 0
@export var duration: float = 1.0
@export var float_distance: float = 30.0

@onready var label: Label = $Label

var elapsed: float = 0.0
var start_position: Vector2


func _ready() -> void:
	if label:
		label.text = str(damage_amount)

	start_position = position


func _process(delta: float) -> void:
	elapsed += delta

	# Calculate progress (0 to 1)
	var progress: float = elapsed / duration

	# Float upward
	position.y = start_position.y - (float_distance * progress)

	# Fade out
	if label:
		label.modulate.a = 1.0 - progress

	# Remove when done
	if elapsed >= duration:
		queue_free()


## Create and spawn a damage popup at a world position.
static func create(damage: int, world_pos: Vector2, parent: Node) -> DamagePopup:
	var popup: DamagePopup = preload("res://scenes/ui/damage_popup.tscn").instantiate()
	popup.damage_amount = damage
	popup.global_position = world_pos
	parent.add_child(popup)
	return popup
