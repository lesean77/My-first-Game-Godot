extends Node2D

@export var rise_distance: float = 20.0
@export var duration: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D

func play(icon: Texture2D) -> void:
	if icon == null:
		queue_free()
		return
		
	sprite.texture = icon
	
	var tween := create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(
		self,
		"position",
		position + Vector2.UP * rise_distance,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		duration
	)
	
	tween.chain().tween_callback(queue_free)
