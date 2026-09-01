extends Node2D

@export var map_data: GeneratedMapData

@onready var tile_map_layer: TileMapLayer = $TileMapLayer2


func _ready() -> void:
	if map_data == null:
		return

	tile_map_layer.tile_set = map_data.tile_set
	tile_map_layer.set_tile_map_data_from_array(
		map_data.tile_map_data
	)
