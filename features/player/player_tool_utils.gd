class_name PlayerToolUtils
extends Node

var player

func setup(player_ref) -> void:
	player = player_ref
	
func get_facing_direction() -> Vector2:
	match player.facing:
		player.Facing.DOWN:
			return Vector2.DOWN
		
		player.Facing.UP:
			return Vector2.UP
			
		player.Facing.SIDE:
			if player.facing_left:
				return Vector2.LEFT
			
			return Vector2.RIGHT
			
	return Vector2.DOWN
	
func get_target_position(distance: float) -> Vector2:
	return player.global_position + get_facing_direction() * distance
