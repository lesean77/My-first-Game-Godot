class_name WorldGrid
extends Node

@export var reference_layer: TileMapLayer

var harvestables: Dictionary = {}

func world_to_cell(world_position: Vector2) -> Vector2i:
	return reference_layer.local_to_map(
		reference_layer.to_local(world_position)
	)
	
func cell_to_world(cell: Vector2i) -> Vector2:
	return reference_layer.to_global(
		reference_layer.map_to_local(cell)
	)
	
func get_target_cell(
	player_position: Vector2,
	mouse_position: Vector2,
	facing_direction: Vector2
) -> Vector2i:
	var player_cell := world_to_cell(player_position)
	var mouse_cell := world_to_cell(mouse_position)
	var offset := mouse_cell - player_cell
	
	if offset != Vector2i.ZERO and absi(offset.x) <= 1 and absi(offset.y) <= 1:
		return mouse_cell
		
	var foward := Vector2i.DOWN
	
	if facing_direction == Vector2.UP:
		foward = Vector2i.UP
	elif facing_direction == Vector2.LEFT:
		foward = Vector2i.LEFT
	elif facing_direction == Vector2.RIGHT:
		foward = Vector2i.RIGHT
	
	return player_cell + foward
		
func get_harvestable(cell: Vector2i) -> Harvestable:
	var target = harvestables.get(cell)
	
	if not is_instance_valid(target):
		return null
	
	if target.is_queued_for_deletion():
		return null
		
	return target as Harvestable
	
func register_harvestable(cell: Vector2i, target: Harvestable) -> bool:
	var existing := get_harvestable(cell)
	
	if existing != null and existing != target:
		push_warning("Dois Harvestables no tile %s." % cell)
		return false
		
	harvestables[cell] = target
	return true
		
func unregister_harvestable(cell: Vector2i, target: Harvestable) -> void:
	if harvestables.get(cell) == target:
		harvestables.erase(cell)
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
