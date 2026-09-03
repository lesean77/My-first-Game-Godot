class_name TargetIndicator
extends Node2D

@export var valid_color: Color = Color.WHITE
@export var invalid_color: Color = Color(1.0, 0.35, 0.35)
@export var locked_color: Color = Color(1.0, 0.85, 0.3)

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	top_level = true
	global_rotation = 0.0
	global_scale = Vector2.ZERO
	
	hide()

func show_target(
	world_position: Vector2,
	is_valid: bool,
	is_locked: bool
) -> void:
	global_position = world_position
	
	if is_locked:
		sprite.modulate = locked_color
	elif is_valid:
		sprite.modulate = valid_color
		
	show()
	
func hide_target() -> void:
	hide()
