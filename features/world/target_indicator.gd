class_name TargetIndicator
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	top_level = true
	global_rotation = 0.0
	global_scale = Vector2.ONE
	z_as_relative = false
	
	hide()

func show_target(
	world_position: Vector2,
	_is_valid: bool,
	_is_locked: bool,
	_above_object: bool = false
) -> void:
	
	global_position = world_position
	

	
	show()
	
func hide_target() -> void:
	hide()
