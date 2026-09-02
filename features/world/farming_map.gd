class_name FarmingMap
extends Node2D

enum SoilState {
	GRASS, 
	DIRT,
	TILLED
}

const TARGET_DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i(1, 1),
	Vector2i.DOWN,
	Vector2i(-1, 1),
	Vector2i.LEFT,
	Vector2i(-1, -1),
	Vector2i.UP,
	Vector2i(1, -1)
]

@onready var target_indicator: Node2D = $TargetIndicator

@export_category("TileMap Layers")

# Mask que define onde é permitido cultivar. 
@export var farmable_layer: TileMapLayer
@export var grass_layer: TileMapLayer
@export var dark_grass_layer: TileMapLayer

@export var soil_layer: TileMapLayer
@export var watered_layer: TileMapLayer

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
@export var tilled_terrain: int = 0

@export var watered_terrain_set: int = 0
@export var watered_terrain: int = 0


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
			"state": get_initial_soil_state(cell),
			"watered": false,
			"crop": null
		}
	
	return cells[cell]

func get_initial_soil_state(cell: Vector2i) -> SoilState:
	var has_grass := grass_layer.get_cell_source_id(cell) != -1
	var has_dark_grass := dark_grass_layer.get_cell_source_id(cell) != -1
	
	if has_grass or has_dark_grass:
		return SoilState.GRASS
		
	return SoilState.DIRT

func get_target_cell(
	player_world_position: Vector2,
	mouse_world_position: Vector2,
	facing_direction: Vector2
) -> Vector2i:
	var player_local := soil_layer.to_local(player_world_position)
	var mouse_local := soil_layer.to_local(mouse_world_position)
	var player_cell := soil_layer.local_to_map(player_local)
	var mouse_cell := soil_layer.local_to_map(mouse_local)
	
	var candidates: Array[Vector2i] = []
	
	if facing_direction == Vector2.UP:
		candidates = [
			player_cell + Vector2i(-1, -1),
			player_cell + Vector2i(0, -1),
			player_cell + Vector2i(1, -1)
		]
		
	elif facing_direction == Vector2.DOWN:
		candidates = [
			player_cell + Vector2i(-1, 1),
			player_cell + Vector2i(0, 1),
			player_cell + Vector2i(1, 1)
		]
		
	elif facing_direction == Vector2.LEFT:
		candidates = [
			player_cell + Vector2i(-1, -1),
			player_cell + Vector2i(-1, 0),
			player_cell + Vector2i(-1, 1)
		]
	
	else: 
		candidates = [
			player_cell + Vector2i(1, -1),
			player_cell + Vector2i(1, 0),
			player_cell + Vector2i(1, 1)
		]
	
	return _get_closest_cell_to_mouse(candidates, mouse_cell)

func _get_closest_cell_to_mouse(
	candidates: Array[Vector2i],
	mouse_cell: Vector2i
) -> Vector2i:
	var closest := candidates[0]
	var closest_distance := INF
	
	for candidate in candidates:
		var distance := Vector2(candidate).distance_squared_to(Vector2(mouse_cell))
		
		if distance < closest_distance:
			closest_distance = distance
			closest = candidate
	
	return closest
	
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
			remove_soil_visual(cell)
			remove_watered_visual(cell)
			
		SoilState.DIRT:
			remove_soil_visual(cell)
			remove_watered_visual(cell)
			
		SoilState.TILLED:
			set_tilled_terrain(cell)
			
			if data["watered"]:
				set_watered_terrain(cell)
			else:
				remove_watered_visual(cell)

# GRASS
func remove_grass(cell: Vector2i) -> void:
	var had_grass := grass_layer.get_cell_source_id(cell) != -1
	var had_dark_grass := dark_grass_layer.get_cell_source_id(cell) != -1
	
	if had_grass:
		erase_grass_terrain(cell)
	
	if had_dark_grass:
		erase_dark_grass_terrain(cell)

func remove_watered_visual(cell: Vector2i) -> void:
	if watered_layer.get_cell_source_id(cell) == -1:
		return
		
	watered_layer.set_cells_terrain_connect(
		[cell],
		watered_terrain_set,
		-1,
		false
	)
	
func remove_soil_visual(cell: Vector2i) -> void:
	if soil_layer.get_cell_source_id(cell) == -1:
		return
	
	soil_layer.set_cells_terrain_connect(
		[cell],
		soil_terrain_set,
		-1,
		false
	)

func update_target_indicator(
	player_position: Vector2,
	mouse_position: Vector2,
	facing_direction: Vector2
) -> void:
	var cell := get_target_cell(player_position, mouse_position, facing_direction)
	
	var local_position := soil_layer.map_to_local(cell)
	
	target_indicator.global_position = soil_layer.to_global(local_position)
	
	target_indicator.visible = is_farmable(cell)

# TILLED
func set_tilled_terrain(cell: Vector2i) -> void:
	soil_layer.set_cells_terrain_connect(
		[cell],
		soil_terrain_set,
		tilled_terrain,
		false
	)

# WATERED
func set_watered_terrain(cell: Vector2i) -> void:
	watered_layer.set_cells_terrain_connect(
		[cell],
		watered_terrain_set,
		watered_terrain,
		false
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

func erase_grass_terrain(cell: Vector2i) -> void:
	if grass_layer.get_cell_source_id(cell) == -1:
		return
	
	grass_layer.set_cells_terrain_connect(
		[cell],
		grass_terrain_set,
		-1,
		false
	)
	
func erase_dark_grass_terrain(cell: Vector2i) -> void:
	if dark_grass_layer.get_cell_source_id(cell) == -1:
		return
		
	dark_grass_layer.set_cells_terrain_connect(
		[cell],
		dark_grass_terrain_set,
		-1,
		false
	)

func show_target_cell(cell: Vector2i) -> void:
	var local_position := soil_layer.map_to_local(cell)
	
	target_indicator.global_position = soil_layer.to_global(local_position)
	
	target_indicator.visible = is_farmable(cell)
