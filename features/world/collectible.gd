class_name Collectible
extends Area2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func get_interactable() -> Node:
	var parent := get_parent()
	
	if parent.has_method("get_action_type") or parent.has_method("interact"):
		return parent
		
	return null
	
func configure(size: Vector2, offset: Vector2) -> void:
	var rectangle := collision_shape.shape as RectangleShape2D

	if rectangle == null:
		push_error(
			"InteractableArea precisa usar RectangleShape2D em: %s"
			% get_path()
		)
		return

	rectangle = rectangle.duplicate()
	collision_shape.shape = rectangle

	rectangle.size = size
	collision_shape.position = offset
