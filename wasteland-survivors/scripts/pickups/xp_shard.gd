class_name XPShard
extends Area2D

## XP shard that can be collected by the player.
## Drops from enemies on death and grants XP when collected.

# Exported variables
@export var xp_value: int = 1
@export var fly_speed: float = 500.0
@export var acceleration: float = 1000.0

# Private variables
var _is_flying_to_player: bool = false
var _current_speed: float = 0.0

# Signal body_entered never connected - XP shards won't be collected
func _on_body_entered(body: Node2D) -> void:
	# Check if the body is the player
	if body.is_in_group("player"):
		# Call collect method on player if it exists
		if body.has_method("collect_xp"):
			body.collect_xp(xp_value)
			queue_free()

func _process(delta: float) -> void:
	if _is_flying_to_player:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			var direction := global_position.direction_to(player.global_position)
			_current_speed = min(_current_speed + acceleration * delta, fly_speed)
			global_position += direction * _current_speed * delta

			# Collect when close enough
			if global_position.distance_to(player.global_position) < 20.0:
				if player.has_method("collect_xp"):
					player.collect_xp(xp_value)
				queue_free()

func fly_to_player() -> void:
	"""Make the XP shard fly towards the player."""
	_is_flying_to_player = true
	_current_speed = 0.0
