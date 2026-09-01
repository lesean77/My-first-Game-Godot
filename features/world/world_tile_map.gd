class_name WorldTileMap
extends Node2D

@onready var fishable_layer: TileMapLayer = $TileMap/Fishable
@onready var farmable_layer: TileMapLayer = $FarmingMap/Farmable
@onready var farming_map: FarmingMap = $FarmingMap
@onready var player = $Player

func _ready() -> void:
	add_to_group("world_map")
	fishable_layer.visible = false
	farmable_layer.visible = false
	
	player.player_farming.set_farming_map(farming_map)

func is_fishable(world_position: Vector2) -> bool:
	var local_position: Vector2 = fishable_layer.to_local(world_position)
	var cell: Vector2i = fishable_layer.local_to_map(local_position)
	
	return fishable_layer.get_cell_source_id(cell) != -1
	
