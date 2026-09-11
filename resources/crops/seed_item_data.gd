class_name SeedItemData
extends ItemData

@export var crop_data: CropData

@export_enum("Simples: 1", "Pacote: 10", "Saco: 30")
var seeds_per_package: int = 1

func is_valid_definition() -> bool:
	return(
		is_valid_item()
		and category == ItemCategory.SEED
		and seeds_per_package in [1, 10, 30]
		and crop_data != null
		and crop_data.is_valid_definition()
	)
