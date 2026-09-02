class_name PlayerFarming
extends Node

var player
var tool_utils : PlayerToolUtils
var farming_map: FarmingMap

var locked_target_cell: Vector2i
var has_locked_target: bool = false

@export var starting_seed_package: SeedItemData
var selected_seed_stack: SeedStack

# Armazenamento provisório dos produtos colhidos.
var harvested_items: Dictionary = {}

func setup(player_ref, tool_utils_ref) -> void:
	player = player_ref
	tool_utils = tool_utils_ref

func _ready() -> void:
	if starting_seed_package != null:
		selected_seed_stack = SeedStack.new(starting_seed_package)
		
func _process(_delta: float) -> void:
	if farming_map == null: 
		return
		
	if not _should_show_target_preview():
		farming_map.hide_target_indicator()
		return
	
	update_target_preview()
	
func set_farming_map(value: FarmingMap) -> void:
	farming_map = value
	
func till_ground(equipment: EquipmentData) -> void:
	if not _can_use_farming_tool(equipment):
		return
		
	if not has_locked_target:
		return
		
	farming_map.till_cell(locked_target_cell)
	
func water_ground(equipment: EquipmentData) -> void:
	if not _can_use_farming_tool(equipment):
		return
		
	if not has_locked_target:
		return
		
	farming_map.water_cell(locked_target_cell)
	
func _can_use_farming_tool(equipment: EquipmentData) -> bool:
	if equipment == null:
		return false
		
	if tool_utils == null:
		return false
	
	if farming_map == null:
		return false
	
	return true

func _get_target_position(equipment: EquipmentData) -> Vector2:
	return tool_utils.get_target_position(equipment.hit_distance)
	
func update_target_preview() -> void:
	if farming_map == null:
		return
	
	if has_locked_target:
		farming_map.show_target_cell(locked_target_cell)
		return
		
	var mouse_position : Vector2 = player.get_global_mouse_position()
	var facing_direction := tool_utils.get_facing_direction()
	
	farming_map.update_target_indicator(player.global_position, mouse_position, facing_direction)

func lock_target() -> void:
	if farming_map == null:
		return
		
	var mouse_position : Vector2 = player.get_global_mouse_position()
	var facing_direction := tool_utils.get_facing_direction()
	
	locked_target_cell = farming_map.get_target_cell(
		player.global_position,
		mouse_position,
		facing_direction
	)
	
	has_locked_target = true

func unlock_target() -> void:
	has_locked_target = false

func _should_show_target_preview() -> bool:
	if player == null:
		return false
	
	if has_locked_target:
		return true
	
	if selected_seed_stack != null and selected_seed_stack.can_plant():
		return true
	
	if farming_map != null and tool_utils != null:
		var target := farming_map.get_target_cell(
			player.global_position,
			player.get_global_mouse_position(),
			tool_utils.get_facing_direction()
		)
		
		var crop := farming_map.get_crop(target)
		
		if crop != null:
			if crop.is_ready_to_harvest() or crop.is_rotten():
				return true
				
	if player.player_equipment == null:
		return false
		
	var equipment: EquipmentData = player.player_equipment.get_selected_equipment()
	
	if equipment == null:
		return false
		
	return (
		equipment.equipment_type == EquipmentData.EquipmentType.HOE
		or equipment.equipment_type == EquipmentData.EquipmentType.WATERING_CAN
	)

func try_plant_selected() -> bool:
	if farming_map == null:
		return false
		
	if player.player_action.is_busy():
		return false
		
	if selected_seed_stack == null:
		return false
		
	if not selected_seed_stack.can_plant():
		return false
		
	lock_target()
	
	var planted := farming_map.plant_crop(
		locked_target_cell,
		selected_seed_stack.item.crop_data
	)
	
	if planted:
		selected_seed_stack.remaining -= 1
	
	unlock_target()
	
	return planted
	
func try_start_crop_collection() -> bool:
	if farming_map == null or player.player_action.is_busy():
		return false
		
	lock_target()
	
	var crop := farming_map.get_crop(locked_target_cell)
	
	if crop == null:
		unlock_target()
		return false
		
	if not crop.is_ready_to_harvest() and not crop.is_rotten():
		unlock_target()
		return false
		
	player.player_interaction.face_position(crop.global_position)
	player.player_action.perform_action(ActionType.Type.COLLECTING, crop)
	
	return true
	
func collect_crop(crop: Crop) -> void:
	if farming_map == null or not has_locked_target:
		return
	
	if not is_instance_valid(crop):
		return
		
	# Revalida o alvo no momento do efeito da animação.
	if farming_map.get_crop(locked_target_cell) != crop:
		return
		
	if crop.is_rotten():
		farming_map.clear_rotten_crop(locked_target_cell)
	else:
		farming_map.harvest_crop(
			locked_target_cell,
			Callable(self, "receive_harvest")
		)

func receive_harvest(item_id: StringName, amount: int) -> bool:
	harvested_items[item_id] = int(harvested_items.get(item_id, 0)) + amount
	
	return true
