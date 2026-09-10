class_name HitArea
extends Area2D

@export var target_path: NodePath

@onready var aim_point: Node2D

func get_target() -> Node:
	if not target_path.is_empty():
		var target := get_node_or_null(target_path)

		if target != null:
			return target

	return get_parent()

func get_aim_position() -> Vector2:
	if is_instance_valid(aim_point):
		return aim_point.global_position
		
	return global_position
