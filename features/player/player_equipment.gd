class_name PlayerEquipment
extends Node

signal selected_equipment_changed(equipment: EquipmentData)

@export var equipment_slots: Array[EquipmentData] = []

var selected_index: int = 0

func _ready() -> void:
	if equipment_slots.is_empty():
		selected_index = -1
		selected_equipment_changed.emit(null)
		return
	
	selected_index = clampi(
		selected_index,
		0,
		equipment_slots.size() - 1
	)
	
	selected_equipment_changed.emit(
		get_selected_equipment()
	)
	
func get_selected_equipment() -> EquipmentData:
	if equipment_slots.is_empty():
		return null
		
	if selected_index < 0 or selected_index >= equipment_slots.size():
		return null
		
	return equipment_slots[selected_index]
	
func select_next_equipment() -> void:
	if equipment_slots.is_empty():
		return
	
	selected_index = wrapi(
		selected_index + 1,
		0,
		equipment_slots.size()
	)
	
	emit_selected_equipment()
	
func select_previous_equipment() -> void:
	if equipment_slots.is_empty():
		return
		
	selected_index = wrapi(
		selected_index - 1,
		0,
		equipment_slots.size()
	)
	
	emit_selected_equipment()
	
func select_equipment(index: int) -> void:
	if index < 0 or index >= equipment_slots.size():
		return
		
	selected_index = index
	emit_selected_equipment()
	
func emit_selected_equipment() -> void:
	var equipment := get_selected_equipment()
	
	selected_equipment_changed.emit(equipment)
	
	if equipment != null:
		print(
			"Equipamento selecionado: ",
			equipment.display_name,
			" | Slot: ", 
			selected_index
		)
