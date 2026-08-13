extends Node

var player : CharacterBody2D

func setup(player_ref : CharacterBody2D) -> void:
	player = player_ref

	
func move(direction : Vector2, speed : float) -> void:
	player.velocity = direction * speed
	player.move_and_slide()
	
func stop() -> void:
	player.velocity = Vector2.ZERO
	player.move_and_slide()
