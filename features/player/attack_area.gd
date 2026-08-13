class_name AttackArea
extends Area2D

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

func configure(size: Vector2, offset: Vector2) -> void:
	var rectangle := collision_shape.shape as RectangleShape2D
	rectangle = rectangle.duplicate()
	collision_shape.shape = rectangle
	
	rectangle.size = size
	position = offset
