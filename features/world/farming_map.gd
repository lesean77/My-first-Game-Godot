class_name FarmingMap
extends Node2D

enum SoilState {
	GRASS, 
	DIRT,
	TILLED
}

@onready var target_indicator: Node2D = $TargetIndicator

@export_category("TileMap Layers")

# Mask que define onde é permitido cultivar. 
@export var farmable_layer: TileMapLayer
@export var grass_layer: TileMapLayer
@export var dark_grass_layer: TileMapLayer

@export var soil_layer: TileMapLayer

# GRASS TERRAIN
@export_category("Grass Terrain")
@export var grass_terrain_set : int = 0
@export var grass_terrain: int = 0

@export var dark_grass_terrain_set : int = 0
@export var dark_grass_terrain : int = 0

# SOIL TERRAIN
@export_category("Soil Terrain")

# Terrain Set usado pelo Soil.
@export var soil_terrain_set: int = 0
@export var watered_terrain: int = 0
@export var tilled_terrain: int = 1

# DATA
var cells: Dictionary = {}

# COORDINATES
func world_to_cell(world_position: Vector2) -> Vector2i:
	var local_position := soil_layer.to_local(world_position)
	return soil_layer.local_to_map(local_position)

# FARMABLE
func is_farmable(cell: Vector2i) -> bool:
	return farmable_layer.get_cell_source_id(cell) != -1
	
# CELL DATA
func get_cell_data(cell: Vector2i) -> Dictionary:
	if not cells.has(cell):
		cells[cell] = {
			"state": SoilState.GRASS,
			"watered": false,
			"crop": null
		}
	
	return cells[cell]

# HOE
func till_cell(cell: Vector2i) -> void:
	if not is_farmable(cell):
		return
		
	var data := get_cell_data(cell)
	
	match data["state"]:
		# GRASS -> DIRT
		SoilState.GRASS:
			data["state"] = SoilState.DIRT
			remove_grass(cell)
		
		# DIRT -> TILLED
		SoilState.DIRT:
			data["state"] = SoilState.TILLED
			data["watered"] = false
			
			refresh_cell_visual(cell)
		
		# TILLED
		SoilState.TILLED:
			return

# WATERING
func water_cell(cell: Vector2i) -> void:
	if not cells.has(cell):
		return
		
	var data: Dictionary = cells[cell]
	
	# Só pode regar terreno arado.
	if data["state"] != SoilState.TILLED:
		return
	
	# Já esta regado. 
	if data["watered"]:
		return
		
	data["watered"] = true
		
	refresh_cell_visual(cell)

# VISUAL
func refresh_cell_visual(cell: Vector2i) -> void:
	if not cells.has(cell):
		return
		
	var data: Dictionary = cells[cell]
	
	match data["state"]:
		
		SoilState.GRASS:
			soil_layer.erase_cell(cell)
			
		SoilState.DIRT:
			soil_layer.erase_cell(cell)
			
		SoilState.TILLED:
			if data["watered"]:
				set_watered_terrain(cell)
			else:
				set_tilled_terrain(cell)

# GRASS
func remove_grass(cell: Vector2i) -> void:
	var had_grass := grass_layer.get_cell_source_id(cell) != -1
	var had_dark_grass := dark_grass_layer.get_cell_source_id(cell) != -1
	
	if had_grass:
		erase_grass_terrain(cell)
	
	if had_dark_grass:
		erase_dark_grass_terrain(cell)


func update_target_indicator(player_position: Vector2, direction: Vector2) -> void:
	var cell := get_target_cell(player_position, direction)
	
	var local_position := soil_layer.map_to_local(cell)
	
	target_indicator.global_position = soil_layer.to_global(local_position)
	
	target_indicator.visible = is_farmable(cell)

# TILLED
func set_tilled_terrain(cell: Vector2i) -> void:
	soil_layer.set_cells_terrain_connect(
		[cell],
		soil_terrain_set,
		tilled_terrain
	)

# WATERED
func set_watered_terrain(cell: Vector2i) -> void:
	soil_layer.set_cells_terrain_connect(
		[cell],
		soil_terrain_set,
		watered_terrain
	)
	
# NEW DAY
func process_new_day() -> void:
	for cell: Vector2i in cells:
		var data: Dictionary = cells[cell]
		
		if data["crop"] != null and data["watered"]:
			if data["crop"].has_method("grow_one_day"):
				data["crop"].grow_one_day()
				
		# Agua dura somente um dia
		data["watered"] = false
		
		refresh_cell_visual(cell)

func get_target_cell(world_position: Vector2, direction: Vector2) -> Vector2i:
	var player_local := soil_layer.to_local(world_position)
	var player_cell := soil_layer.local_to_map(player_local)
	
	var cell_direction := Vector2i(
		roundi(direction.x),
		roundi(direction.y)
	)
	
	return player_cell + cell_direction

func till_from_player(player_position: Vector2, direction: Vector2) -> void:
	var cell := get_target_cell(player_position, direction)
	
	till_cell(cell)
	
func water_from_player(player_position: Vector2, direction: Vector2) -> void:
	var cell := get_target_cell(player_position, direction)
	
	water_cell(cell)

func erase_grass_terrain(cell: Vector2i) -> void:
	if grass_layer.get_cell_source_id(cell) == -1:
		return
	
	_reconnect_terrain_around(grass_layer, cell, grass_terrain_set, grass_terrain)
	
func erase_dark_grass_terrain(cell: Vector2i) -> void:
	if dark_grass_layer.get_cell_source_id(cell) == -1:
		return
		
	dark_grass_layer.erase_cell(cell)
	
	_reconnect_terrain_around(dark_grass_layer, cell, dark_grass_terrain_set, dark_grass_terrain)
#teste
func _reconnect_terrain_around(
	layer: TileMapLayer,
	cell: Vector2i,
	terrain_set: int,
	_terrain: int
) -> void:
	var cells_to_update : Array[Vector2i] = []
	
	for x in range(-1, 1):
		for y in range(-1, 1):
			var neighbor := cell + Vector2i(x, y)
			
			if neighbor == cell:
				continue
				
			if layer.get_cell_source_id(neighbor) != -1:
				cells_to_update.append(neighbor)
	
	if cells_to_update.is_empty():
		return
	
	layer.set_cells_terrain_connect(
		cells_to_update,
		terrain_set,
		-1,
		false
	)
