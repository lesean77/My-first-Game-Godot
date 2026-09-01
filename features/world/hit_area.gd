class_name HitArea
extends Area2D

@export var target_path: NodePath

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func configure(size: Vector2, offset: Vector2) -> void:
	var rectangle := collision_shape.shape as RectangleShape2D

	if rectangle == null:
		push_warning("HitArea precisa usar RectangleShape2D.")
		return

	var unique_rectangle := rectangle.duplicate() as RectangleShape2D
	collision_shape.shape = unique_rectangle

	unique_rectangle.size = size
	collision_shape.position = offset


func get_target() -> Node:
	if not target_path.is_empty():
		var configured_target := get_node_or_null(target_path)

		if configured_target != null:
			return configured_target

	return get_parent()

func get_aim_position() -> Vector2:
	if collision_shape != null:
		return collision_shape.global_position
		
	return global_position
