class_name PlayerFarming
extends Node

var player
var tool_utils : PlayerToolUtils
var farming_map: FarmingMap

var locked_target_cell: Vector2i
var has_locked_target: bool = false

func setup(player_ref, tool_utils_ref) -> void:
	player = player_ref
	tool_utils = tool_utils_ref
	
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
		
	if player.player_equipment == null:
		return false
		
	var equipment: EquipmentData = player.player_equipment.get_selected_equipment()
	
	if equipment == null:
		return false
		
	return (
		equipment.equipment_type == EquipmentData.EquipmentType.HOE
		or equipment.equipment_type == EquipmentData.EquipmentType.WATERING_CAN
	)
