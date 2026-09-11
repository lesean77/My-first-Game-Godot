class_name ItemData
extends Resource

enum ItemCategory {
	RESOURCE,
	CROP,
	SEED,
	EQUIPMENT,
	CONSUMABLE
}

@export_category("Identity")
@export var id: StringName
@export var display_name: String = "Item"
@export_multiline var description: String
@export var icon: Texture2D

@export_category("Inventory")
@export var category: ItemCategory = ItemCategory.RESOURCE
@export_range(1, 999, 1) var max_stack: int = 999

func is_valid_item() -> bool:
	return (
		id != &""
		and not display_name.is_empty()
		and max_stack > 0
	)
