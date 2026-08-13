extends Node2D

enum TerrainType {
	WATER,
	SAND,
	GRASS
}

@onready var water_layer: TileMapLayer = $Water
@onready var ground_layer: TileMapLayer = $Ground

@export_category("Map")
@export var map_width: int = 200
@export var map_height: int = 200

@export_category("Noise")
@export var noise_texture: NoiseTexture2D
@export var randomize_seed: bool = true
@export var seed_in: int = 12345

@export_category("Terrain Limits")
@export_range(-1.0, 1.0, 0.01) var water_limit: float = -0.25
@export_range(-1.0, 1.0, 0.01) var sand_limit: float = -0.05

@export_category("Water Solid Tile")
@export var water_source_id: int = 6
@export var water_atlas_coords: Vector2i = Vector2i(9, 2)

@export_category("Ground Solid Tiles")
@export var grass_source_id: int = 4
@export var grass_atlas_coords: Vector2i = Vector2i(9, 2)

@export var sand_source_id: int = 5
@export var sand_atlas_coords: Vector2i = Vector2i(9, 2)

const GROUND_TERRAIN_SET := 0
const GRASS_TERRAIN := 0
const SAND_TERRAIN := 1
 
var terrain_map: Dictionary = {}

func _ready() -> void:
	generate_map()


func generate_map() -> void:
	if noise_texture == null:
		push_error("NoiseTexture2D não foi configurado.")
		return

	if noise_texture.noise == null:
		push_error("NoiseTexture2D não possui Noise.")
		return

	var total_start := Time.get_ticks_msec()

	configure_seed()

	water_layer.clear()
	ground_layer.clear()
	terrain_map.clear()

	generate_terrain_data()

	var water_start := Time.get_ticks_msec()
	paint_water_base()
	print("Water: ", Time.get_ticks_msec() - water_start, " ms")

	var ground_start := Time.get_ticks_msec()
	paint_ground_optimized()
	print("Ground: ", Time.get_ticks_msec() - ground_start, " ms")

	print(
		"Mapa gerado em ",
		Time.get_ticks_msec() - total_start,
		" ms"
	)
	
func generate_terrain_data() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var cell := Vector2i(x, y)

			var noise_value := noise_texture.noise.get_noise_2d(
				float(x),
				float(y)
			)

			if noise_value < water_limit:
				terrain_map[cell] = TerrainType.WATER
			elif noise_value < sand_limit:
				terrain_map[cell] = TerrainType.SAND
			else:
				terrain_map[cell] = TerrainType.GRASS

func paint_water_base() -> void:
	for x in range(map_width):
		for y in range(map_height):
			water_layer.set_cell(
				Vector2i(x, y),
				water_source_id,
				water_atlas_coords
			)

func paint_ground_optimized() -> void:
	var sand_borders: Array[Vector2i] = []
	var grass_borders: Array[Vector2i] = []

	for x in range(map_width):
		for y in range(map_height):
			var cell := Vector2i(x, y)
			var terrain: TerrainType = terrain_map[cell]

			if terrain == TerrainType.WATER:
				continue

			# Primeiro coloca o tile sólido em todas as células.
			match terrain:
				TerrainType.SAND:
					ground_layer.set_cell(
						cell,
						sand_source_id,
						sand_atlas_coords
					)

				TerrainType.GRASS:
					ground_layer.set_cell(
						cell,
						grass_source_id,
						grass_atlas_coords
					)

			# Depois registra somente as células que precisam
			# ser recalculadas pelo Terrain Connect.
			if is_border_cell(cell, terrain):
				match terrain:
					TerrainType.SAND:
						sand_borders.append(cell)

					TerrainType.GRASS:
						grass_borders.append(cell)

	if not sand_borders.is_empty():
		ground_layer.set_cells_terrain_connect(
			sand_borders,
			GROUND_TERRAIN_SET,
			SAND_TERRAIN,
			false
		)

	if not grass_borders.is_empty():
		ground_layer.set_cells_terrain_connect(
			grass_borders,
			GROUND_TERRAIN_SET,
			GRASS_TERRAIN,
			false
		)
		
func is_border_cell(
	cell: Vector2i,
	terrain: TerrainType
) -> bool:
	var directions: Array[Vector2i] = [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1)
	]

	for direction in directions:
		var neighbor := cell + direction

		if not terrain_map.has(neighbor):
			return true

		if terrain_map[neighbor] != terrain:
			return true

	return false
	
func configure_seed() -> void:
	var fast_noise := noise_texture.noise as FastNoiseLite

	if fast_noise == null:
		push_warning("O Noise não é FastNoiseLite.")
		return

	if randomize_seed:
		fast_noise.seed = randi()
	else:
		fast_noise.seed = seed_in
