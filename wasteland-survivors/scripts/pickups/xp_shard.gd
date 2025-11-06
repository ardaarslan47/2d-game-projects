class_name XPShard
extends Area2D

## XP shard that can be collected by the player.
## Drops from enemies on death and grants XP when collected.

# Exported variables
@export var xp_value: int = 1

# Signal body_entered never connected - XP shards won't be collected
func _on_body_entered(body: Node2D) -> void:
	# Check if the body is the player
	if body.is_in_group("player"):
		# Call collect method on player if it exists
		if body.has_method("collect_xp"):
			body.collect_xp(xp_value)
			queue_free()
