class_name PlayerFarming
extends Node

var player
var tool_utils : PlayerToolUtils

func setup(player_ref, tool_utils_ref) -> void:
	player = player_ref
	tool_utils = tool_utils_ref
	
func till_ground(equipment: EquipmentData) -> void:
	if equipment == null:
		push_warning("Não foi possivel arar: equipamento nulo.")
		return
	
	if tool_utils == null:
		push_error(
			"PlayerFarming não recebeu PlayerToolUtils no setup()."
		)
		return
		
	var target_position := tool_utils.get_target_position(equipment.hit_distance)
	
	print(
		"Tentando arar terreno em: ",
		target_position
	)
	#farming_map.till_at_world_position(target_position)
func water_ground(equipment: EquipmentData) -> void:
	if equipment == null:
		push_warning("Não foi possivel regar: equipamento nulo.")
		return
	
	if tool_utils == null:
		push_error(
			"PlayerFarming não recebeu PlayerToolUtils no setup()."
		)
		return
		
	var target_position := tool_utils.get_target_position(equipment.hit_distance)
	
	print(
		"Tentando regar terreno em: ",
		target_position	
	)
	
	#farming_map.water_at_world_position(target_position)
