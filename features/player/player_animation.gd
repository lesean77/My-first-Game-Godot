class_name PlayerAnimation
extends Node

var player
var player_action
var playback : AnimationNodeStateMachinePlayback
var fishing_playback : AnimationNodeStateMachinePlayback

@onready var animation_tree : AnimationTree = $"../AnimationTree"
@onready var animated_sprite : AnimatedSprite2D = $"../AnimatedSprite2D"

func setup(player_ref, action_ref) -> void:
	player = player_ref
	player_action = action_ref
	
	animation_tree.active = true
	
	playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
	fishing_playback = animation_tree.get("parameters/Fishing/playback") as AnimationNodeStateMachinePlayback
	
	if playback == null:
		push_error(
			"PlayerAnimation: playback principal não foi encontrado."
		)
		
	if fishing_playback == null:
		push_error(
			"PlayerAnimation: playback interno de Fishing não foi encontrado."
		)
		
	print("Playback principal: ", playback)
	print("Playback Fishing: ", fishing_playback)
	
func set_animation(state_name : String) -> void:
	update_blend_position()
	update_sprite_flip()
	
	if state_name == &"Fishing":
		enter_fishing()
		return
		
	if is_action_animation(state_name):
		play_action_animation(state_name)
	else:
		travel_to(state_name)

func play_action_animation(state_name: String) -> void:
	if playback == null:
		push_error("AnimationTree playback não foi configurado.")
		return
		
	print(
		"Forçando animação de ação: ",
		playback.get_current_node(),
		" -> ",
		state_name
	)
	
	playback.start(state_name, true)
	
func travel_to(state_name : String) -> void:
	if playback == null:
		push_error("AnimationTree playback não foi configurado.")
		return
	
	if playback.get_current_node() == state_name:
		return
		
	playback.travel(state_name)

func is_action_animation(state_name: String) -> bool:
	return state_name in [
		"Attack",
		"Crush",
		"Slice",
		"Tilling",
		"Watering",
		"Collect",
		"Fishing",
		"Hurt",
		"Death"
	]

func enter_fishing() -> void:
	update_blend_position()
	update_sprite_flip()
	
	if playback == null:
		push_error(
			"PlayerAnimation: playback principal não foi configurado."
		)
		return
	
	playback.start(&"Fishing", true)
	
	await get_tree().process_frame
	
	fishing_playback = animation_tree.get(
		"parameters/Fishing/playback"
	) as AnimationNodeStateMachinePlayback
	
	if fishing_playback == null:
		push_error(
			"PlayerAnimation: playback de Fishing não foi configurado."
		)
		return
		
	fishing_playback.start(&"Prepare", true)
	
	print("Animação de pesca iniciada: Fishing/Prepare")

func set_fishing_state(state_name: StringName) -> void:
	if playback == null:
		push_error(
			"PlayerAnimation: playback principal não foi configurado."
		)
		return

	if playback.get_current_node() != &"Fishing":
		playback.start(&"Fishing", true)
		await get_tree().process_frame

	if fishing_playback == null:
		fishing_playback = animation_tree.get(
			"parameters/Fishing/playback"
		) as AnimationNodeStateMachinePlayback

	if fishing_playback == null:
		push_error(
			"Playback interno de Fishing não encontrado."
		)
		return

	print(
		"Fishing: ",
		fishing_playback.get_current_node(),
		" -> ",
		state_name
	)

	fishing_playback.start(state_name, true)
	
	if state_name == &"Fighting":
		var blend := get_blend_position()

		print("Facing atual: ", player.facing)
		print("Facing left: ", player.facing_left)
		print("Fighting blend: ", blend)

		animation_tree.set(
			"parameters/Fishing/Fighting/BlendSpace2D/blend_position",
			blend
		)
	# Reaplica após entrar no estado.
	update_blend_position()
	update_sprite_flip()

func get_fishing_playback() -> AnimationNodeStateMachinePlayback:
	var internal_playback := animation_tree.get("parameters/Fishing/playback") as AnimationNodeStateMachinePlayback
	
	if internal_playback == null:
		push_error(
			"Playback interno de Fishing nao encontrado. " +
			"Verifique se Fishing é uma StateMachine."
		)
		
	return internal_playback
	
func exit_fishing(next_state: StringName = &"Idle") -> void:
	if playback == null:
		return
	
	playback.start(next_state, true)
	
func get_current_fishing_state() -> StringName:
	if fishing_playback == null:
		return &""
		
	return fishing_playback.get_current_node()
	
func update_blend_position() -> void:
	if player == null:
		return
		
	var blend_position := get_blend_position()
	
	set_blend_position("parameters/Idle/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Walk/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Run/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Attack/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Crush/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Slice/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Tilling/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Collect/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Hurt/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Death/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Watering/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Fishing/Prepare/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Fishing/Cast/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Fishing/Waiting/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Fishing/Fighting/BlendSpace2D/blend_position", blend_position)
	set_blend_position("parameters/Fishing/CancelCast/BlendSpace2D/blend_position", blend_position)

func set_blend_position(property_path: String, blend_position: Vector2) -> void:
	if animation_tree == null:
		return
	
	animation_tree.set(property_path, blend_position)
	
func get_blend_position() -> Vector2:
	match player.facing:
		player.Facing.DOWN:
			return Vector2.DOWN
		player.Facing.UP:
			return Vector2.UP
		player.Facing.SIDE:
			return Vector2.RIGHT
	return Vector2.DOWN
	
func update_sprite_flip() -> void:
	if player == null:
		return
		
	if player.facing == player.Facing.SIDE:
		animated_sprite.flip_h = player.facing_left
	else:
		animated_sprite.flip_h = false
		

func update_movement_animation() -> void:
	if player_action != null and player_action.is_busy():
		return
	
	if player.velocity == Vector2.ZERO:
		set_animation(&"Idle")
	else:
		set_animation(&"Run")
