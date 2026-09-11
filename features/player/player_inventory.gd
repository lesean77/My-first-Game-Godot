class_name PlayerInventory
extends Node

signal inventory_changed
signal slot_changed(index: int)
signal selected_slot_changed(index: int)

@export_range(40, 80, 10) var capacity: int = 40

var slots: Array[InventorySlot] = []
var selected_slot_index: int = 0

func _ready() -> void:
	initialize_slots()
	
func initialize_slots() -> void:
	if slots.size() == capacity:
		return
		
	slots.clear()
	
	for index in capacity:
		slots.append(InventorySlot.new())
	
	selected_slot_index = clampi(selected_slot_index, 0, capacity - 1)
	
	inventory_changed.emit()
	
func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= slots.size():
		return null
		
	return slots[index]
	
func get_selected_slot() -> InventorySlot:
	return get_slot(selected_slot_index)
	
func select_slot(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	
	if selected_slot_index == index:
		return
		
	selected_slot_index = index
	selected_slot_changed.emit(index)
	
func count_item(item_id: StringName) -> int:
	var total := 0
	
	for slot in slots:
		if (
			not slot.is_empty()
			and slot.item.id == item_id
		):
			total += slot.amount
			
	return total
	
func can_add_item(item: ItemData, amount: int) -> bool:
	if item == null or amount <= 0:
		return false
	
	var available_space := 0
	
	for slot in slots:
		if slot.is_empty():
			available_space += item.max_stack
		elif slot.item.id == item.id:
			available_space += slot.get_free_space()
			
		if available_space >= amount:
			return true
			
	return false
	
func add_item(item: ItemData, amount: int = 1) -> bool:
	if not can_add_item(item, amount):
		return false
	
	var remaining := amount
	
	for index in slots.size():
		var slot := slots[index]
		
		if not slot.can_receive(item):
			continue
			
		var added := mini(slot.get_free_space(), remaining)
		
		slot.amount += added
		remaining -= added
		slot_changed.emit(index)
		
		if remaining == 0:
			inventory_changed.emit()
			return true
			
	for index in slots.size():
		var slot := slots[index]
		
		if not slot.is_empty():
			continue
			
		var added := mini(item.max_stack, remaining)
		
		slot.item = item
		slot.amount = added
		remaining -= added
		slot_changed.emit(index)
		
		if remaining == 0:
			inventory_changed.emit()
			return true
		
	return false
	
func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0:
		return false
	
	if count_item(item_id) < amount:
		return false
		
	var remaining := amount
	
	for index in range(slots.size() -1, -1, -1):
		var slot := slots[index]
		
		if slot.is_empty() or slot.item.id != item_id:
			continue
			
		var removed := mini(slot.amount, remaining)
		
		slot.amount -= removed
		remaining -= removed
		
		if slot.amount <= 0:
			slot.clear()
			
		slot_changed.emit(index)
		
		if remaining == 0:
			inventory_changed.emit()
			return true
		
	return false
	
func consume_selected(amount: int = 1) -> bool:
	var slot := get_selected_slot()
	
	if slot == null or slot.is_empty():
		return false
		
	if slot.amount < amount:
		return false
		
	slot.amount -= amount
	
	if slot.amount <= 0:
		slot.clear()
		
	slot_changed.emit(selected_slot_index)
	inventory_changed.emit()
	return true
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
