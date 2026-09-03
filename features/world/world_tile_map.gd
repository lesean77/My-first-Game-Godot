class_name WorldTileMap
extends Node2D

@onready var fishable_layer: TileMapLayer = $TileMap/Fishable
@onready var farmable_layer: TileMapLayer = $FarmingMap/Farmable
@onready var farming_map: FarmingMap = $FarmingMap
@onready var player = $Player

@onready var world_grid: WorldGrid = $WorldGrid

func _ready() -> void:
	add_to_group("world_map")
	fishable_layer.visible = false
	farmable_layer.visible = false
	
	player.player_targeting.set_grid(world_grid)
	player.player_farming.set_farming_map(farming_map)
	player.player_fishing.set_fishable_layer(fishable_layer)
	

func is_fishable(world_position: Vector2) -> bool:
	var local_position: Vector2 = fishable_layer.to_local(world_position)
	var cell: Vector2i = fishable_layer.local_to_map(local_position)
	
	return fishable_layer.get_cell_source_id(cell) != -1
	
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	
	if not event.is_action_pressed("debug_next_day"):
		return
	
	if event.is_echo():
		return
		
	if player.player_action.is_busy():
		return
		
	if player.player_fishing.is_active():
		return
		
	farming_map.process_new_day(farming_map.current_day + 1)
	get_viewport().set_input_as_handled()
