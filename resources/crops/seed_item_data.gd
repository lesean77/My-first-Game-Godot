class_name SeedItemData
extends Resource

@export var id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var crop_data: CropData

@export_enum("Simples: 1", "Pacote: 10", "Saco: 30")
var seeds_per_package: int = 1

func is_valid_definition() -> bool:
	return(
		id != &""
		and seeds_per_package in [1, 10, 30]
		and crop_data != null
		and crop_data.is_valid_definition()
	)
