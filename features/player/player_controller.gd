extends Node

var player
var player_input
var player_movement
var player_animation
var player_interaction
var player_action
var player_attack
var player_equipment : PlayerEquipment
var player_farming
var player_fishing
var player_tool_utils
var fishing_ui : FishingUI

var is_performing_action : bool = false

func setup(
	player_ref,
	input_ref,
	movement_ref,
	animation_ref,
	interaction_ref,
	action_ref,
	attack_ref,
	equipment_ref : PlayerEquipment,
	farming_ref,
	fishing_ref,
	tool_utils_ref,
	fishing_ui_ref) -> void:
		
	player = player_ref
	player_input = input_ref
	player_movement = movement_ref
	player_animation = animation_ref
	player_interaction = interaction_ref
	player_action = action_ref
	player_attack = attack_ref
	player_equipment = equipment_ref
	player_farming = farming_ref
	player_fishing = fishing_ref
	player_tool_utils = tool_utils_ref
	fishing_ui = fishing_ui_ref
	
	player_movement.setup(player)
	player_animation.setup(player, player_action)
	player_interaction.setup(player)
	
	player_tool_utils.setup(player)
	
	
	player_attack.setup(player, player_action, player_equipment, player_interaction)
	player_farming.setup(player, player_tool_utils)
	player_fishing.setup(player, player_animation, player_action)
	player_action.setup(player, player_animation, player_attack, player_farming, player_fishing)
	fishing_ui.setup(player_fishing)
	
	if not player_action.action_finished.is_connected(_on_action_finished):
		player_action.action_finished.connect(_on_action_finished)
		
func physics_update(_delta : float) -> void:
	handle_equipment_selection()
	update_target_preview()
	
	if player_fishing.is_active():
		player_movement.stop()
		
		if player_input.wants_cancel_action():
			player_fishing.cancel_fishing()
			return
		
		if player_fishing.state == PlayerFishing.FishingState.PREPARING:
			update_facing_toward_mouse()
			
		player_fishing.physics_update(_delta)
		
		if player_input.wants_attack():
			handle_fishing_press()
			
		if player_input.released_attack():
			handle_fishing_release()
		return
	
	if player_action.is_busy():
		player_movement.stop()
		return
	
	if Input.is_action_just_pressed("plant_seed"):
		player_movement.stop()
		player_farming.try_plant_selected()
		return
	
	if Input.is_action_just_pressed("collect_crop"):
		player_movement.stop()
		player_farming.try_start_crop_collection()
		return
		
	if player_input.wants_attack():
		start_attack()
		return
		
	if player_input.wants_interact():
		start_interaction()
		return
	
	var direction : Vector2 = player_input.get_move_direction()
	
	update_facing(direction)
	
	var speed := get_current_speed()
	
	player_movement.move(direction, speed)
	update_animation(direction)

func update_facing_toward_mouse() -> void:
	var mouse_position: Vector2 = (player.get_global_mouse_position())
	
	var direction: Vector2 = mouse_position - player.global_position
	
	if direction.length_squared() <= 4.0:
		return
		
	var horizontal_amount: float = absf(direction.x)
	var vertical_amount: float = absf(direction.y)
		
	if horizontal_amount >= vertical_amount:
		player.facing = player.Facing.SIDE
		player.facing_left = direction.x < 0.0
	else:
		player.facing_left = false
		
		if direction.y > 0.0:
			player.facing = player.Facing.DOWN
		else:
			player.facing = player.Facing.UP
			
	player_animation.update_blend_position()
	player_animation.update_sprite_flip()
	
# PESCA
func handle_fishing_press() -> void:
	match player_fishing.state:
		PlayerFishing.FishingState.FISH_ON_HOOK:
			player_fishing.hook_fish()
			
func handle_fishing_release() -> void:
	match player_fishing.state:
		PlayerFishing.FishingState.PREPARING:
			player_fishing.confirm_cast()
		
# EQUIPAMENTOS
func handle_equipment_selection() -> void:
	if player_fishing.is_active():
		return
		
	if player_input.wants_next_tool():
		player_equipment.select_next_equipment()
		
	if player_input.wants_previous_tool():
		player_equipment.select_previous_equipment()

# ATAQUE
func start_attack() -> void:
	is_performing_action = true
	player_movement.stop()
	
	var equipment : EquipmentData = player_equipment.get_selected_equipment()
	
	if(equipment != null and equipment.equipment_type == EquipmentData.EquipmentType.FISHING_ROD):
		update_facing_toward_mouse()
		
	if not player_attack.request_attack():
		is_performing_action = false

# INTERAÇÃO
func start_interaction() -> void:
	if is_performing_action:
		return
		
	is_performing_action = true
	player_movement.stop()
	
	request_interact()
	
func request_interact() -> void:
	player_interaction.try_interact()

# MOVIMENTO E ANIMAÇÃO
func update_animation(direction : Vector2) -> void:
	if direction == Vector2.ZERO:
		player_animation.set_animation("Idle")
	elif player.is_low_health():
		player_animation.set_animation("Walk")
	else:
		player_animation.set_animation("Run")

func update_facing(direction : Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	
	if not is_zero_approx(direction.x):
		player.facing = player.Facing.SIDE
		player.facing_left = direction.x < 0
	else:
		if direction.y > 0:
			player.facing = player.Facing.DOWN
		else:
			player.facing = player.Facing.UP
	
	player_animation.update_sprite_flip()
	player_interaction.update_interaction_position()

func get_current_speed() -> float:
	if player.is_low_health():
		return player.walk_speed
		
	return player.run_speed

# SINAIS
func _on_action_finished() -> void:
	is_performing_action = false

func update_target_preview() -> void:
	var targeting: PlayerTargeting = player.player_targeting
	
	var validator := Callable()
	
	if not is_instance_valid(targeting.grid):
		targeting.update_preview(validator)
		return
	
	var equipment: EquipmentData = player_equipment.get_selected_equipment()
	
	if equipment != null:
		match equipment.equipment_type:
			EquipmentData.EquipmentType.PICKAXE:
				validator = Callable(
					player_attack,
					"can_hit_cell"
				).bind(equipment)
				
			EquipmentData.EquipmentType.HOE:
				validator = Callable(player_farming, "can_till")
			
			EquipmentData.EquipmentType.WATERING_CAN:
				validator = Callable(player_farming, "can_water")
	
	if not validator.is_valid():
		var cell := targeting.get_target_cell()
		
		if player_farming.can_collect(cell):
			validator = Callable(player_farming, "can_collect")
		elif (
			player_farming.selected_seed_stack != null
			and player_farming.selected_seed_stack.can_plant()
		):
			validator = Callable(player_farming, "can_plant")
	
	targeting.update_preview(validator)
