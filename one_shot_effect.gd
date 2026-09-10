class_name OneShotEffect
extends Node2D

@export var animation_name: StringName = &"default"
@export var random_flip_h: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if animated_sprite.sprite_frames == null:
		queue_free()
		return
		
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		push_warning("Animação não encontrada no efeito: %s" % animation_name)
		queue_free()
		return
		
	animated_sprite.flip_h = random_flip_h and randf() < 0.5
	
	animated_sprite.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	
	animated_sprite.play(animation_name)
	
func _on_animation_finished() -> void:
	queue_free()
