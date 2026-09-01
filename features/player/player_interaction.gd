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
	if target == null:
		return
		
	face_position(target.global_position)
	
func face_position(target_position: Vector2) -> void:
	var direction: Vector2 = target_position - player.global_position
	
	if direction.length_squared() <= 0.001:
		return
	
	var horizontal_distance := absf(direction.x)
	var vertical_distance := absf(direction.y)
	
	if horizontal_distance > vertical_distance:
		player.facing = player.Facing.SIDE
		player.facing_left = direction.x < 0.0
	
	else:
		player.facing_left = false
		
		if direction.y < 0.0:
			player.facing = player.Facing.UP
		else:
			player.facing = player.Facing.DOWN
			
	player.player_animation.update_blend_position()
	player.player_animation.update_sprite_flip()
	player.player_interaction.update_interaction_position()
	
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
