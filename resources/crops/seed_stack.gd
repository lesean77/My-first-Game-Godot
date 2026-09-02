class_name SeedStack
extends RefCounted

var item: SeedItemData
var remaining: int = 0

func _init(definition: SeedItemData = null) -> void:
	item = definition
	
	if item != null and item.is_valid_definition():
		remaining = item.seeds_per_package
		
func can_plant() -> bool:
	return (
		item != null
		and item.is_valid_definition()
		and remaining > 0
	)
