class_name PlayerFarming
extends Node

var player
var tool_utils : PlayerToolUtils
var farming_map: FarmingMap

func setup(player_ref, tool_utils_ref) -> void:
	player = player_ref
	tool_utils = tool_utils_ref
	
func _process(_delta: float) -> void:
	if farming_map == null: 
		return
		
	update_target_preview()
	
func set_farming_map(value: FarmingMap) -> void:
	farming_map = value
	
func till_ground(equipment: EquipmentData) -> void:
	if not _can_use_farming_tool(equipment):
		return
		
	var direction := tool_utils.get_facing_direction()
		
	farming_map.till_from_player(
		player.global_position,
		direction
	)
	
func water_ground(equipment: EquipmentData) -> void:
	if not _can_use_farming_tool(equipment):
		return
		
	var direction := tool_utils.get_facing_direction()
	
	farming_map.water_from_player(
		player.global_position,
		direction
	)

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
		
	var direction := tool_utils.get_facing_direction()
	
	farming_map.update_target_indicator(player.global_position, direction)
