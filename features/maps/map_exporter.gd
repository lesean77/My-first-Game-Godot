@tool
extends Node

@export var tile_map_layer: TileMapLayer

@export_tool_button("Salvar mapa gerado", "Save")
var save_map_button := save_generated_map


const SAVE_DIRECTORY := "res://maps/generated/"
const FILE_PREFIX := "world_"


func save_generated_map() -> void:
	if tile_map_layer == null:
		push_error("Defina o TileMapLayer no Inspector.")
		return

	var map_data := GeneratedMapData.new()

	map_data.tile_set = tile_map_layer.tile_set
	map_data.tile_map_data = tile_map_layer.get_tile_map_data_as_array()

	var path := get_next_map_path()

	var error := ResourceSaver.save(map_data, path)

	if error == OK:
		print("Mapa salvo em: ", path)
	else:
		push_error("Erro ao salvar mapa. Código: %s" % error)


func get_next_map_path() -> String:
	var index := 1

	while true:
		var file_name := "%s%03d.res" % [FILE_PREFIX, index]
		var path := SAVE_DIRECTORY + file_name

		if not FileAccess.file_exists(path):
			return path

		index += 1

	return ""
