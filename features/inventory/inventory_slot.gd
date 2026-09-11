class_name InventorySlot
extends Resource

@export var item: ItemData
@export_range(0, 999, 1) var amount: int = 0

func is_empty() -> bool: 
	return item == null or amount <= 0

func clear() -> void:
	item = null
	amount = 0
	
func get_free_space() -> int:
	if is_empty():
		return 0
		
	return maxi(item.max_stack - amount, 0)
	
func can_receive(target_item: ItemData) -> bool:
	return (
		target_item != null
		and not is_empty()
		and item.id == target_item.id
		and amount < item.max_stack
	)
