extends Node

var player
var current_interactable : Node = null

@onready var interaction_area : Area2D = $"../InteractionArea"

func setup(player_ref) -> void:
	player = player_ref
	
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)
	
func try_interact() -> void:
	if current_interactable == null:
		print("Nada para interagir")
		return
	
	face_target(current_interactable)
	
	print("Interagindo com: ", current_interactable.name)
	
	if current_interactable.has_method("get_action_type"):
		var action_type = current_interactable.get_action_type()
		player.player_action.perform_action(action_type, current_interactable)
		return
		
	if current_interactable.has_method("interact"):
		current_interactable.interact(player)
		
func update_interaction_position() -> void:
	match player.facing:
		player.Facing.DOWN:
			interaction_area.position = Vector2(0, 0)
		player.Facing.UP:
			interaction_area.position = Vector2(0, 0)
		player.Facing.SIDE:
			if player.facing_left:
				interaction_area.position = Vector2(0, 0)
			else:
				interaction_area.position = Vector2(0, 0)

func face_target(target : Node2D) -> void:
	var direction : Vector2 = target.global_position - player.global_position
	
	if abs(direction.y) >= abs(direction.x):
		if direction.y < 0:
			player.facing = player.Facing.UP
		else:
			player.facing = player.Facing.DOWN
	else:
		player.facing = player.Facing.SIDE
		player.facing_left = direction.x < 0
		
	player.player_animation.update_sprite_flip()
	player.player_animation.update_blend_position()
	
func _on_area_entered(area : Area2D) -> void:
	if area is Collectible:
		var target : Node = area.get_interactable()
		
		if target != null:
			current_interactable = target
			print("Interactable detectado: ", target.name)
			
func _on_area_exited(area : Area2D) -> void:
	if not area is Collectible:
		return
	
	var target : Node = area.get_interactable()
	
	if target == current_interactable:
		current_interactable = null
