class_name InventoryUI
extends CanvasLayer

const SLOT_SCENE: PackedScene = preload("res://features/inventory/inventory_slot_ui.tscn")

@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var ui_root: Control = $Root

var player_inventory: PlayerInventory
var slot_views: Array[InventorySlotUI] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.hide()

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
		
	if event.is_action_pressed("toggle_inventory"):
		if ui_root.visible:
			close_inventory()
		else:
			open_inventory()
			
		get_viewport().set_input_as_handled()
	
	elif ui_root.visible and event.is_action_pressed("ui_cancel"):
		close_inventory()
		get_viewport().set_input_as_handled()

func open_inventory() -> void:
	ui_root.show()
	get_tree().paused = true

func close_inventory() -> void:
	ui_root.hide()
	get_tree().paused = false
	
	
func setup(inventory: PlayerInventory) -> void:
	if player_inventory != null:
		if player_inventory.inventory_changed.is_connected(_refresh_inventory):
			player_inventory.inventory_changed.disconnect(_refresh_inventory)
	
	player_inventory = inventory
	
	if player_inventory != null:
		player_inventory.inventory_changed.connect(_refresh_inventory)
	
	_refresh_inventory()

func _refresh_inventory() -> void:
	var slot_count: int = 0
	
	if player_inventory != null:
		slot_count = player_inventory.slots.size()
		
	if slot_views.size() != slot_count:
		for slot_view in slot_views:
			inventory_grid.remove_child(slot_view)
			slot_view.queue_free()
		
		slot_views.clear()
		
		for index in range(slot_count):
			var slot_view := SLOT_SCENE.instantiate() as InventorySlotUI
			inventory_grid.add_child(slot_view)
			slot_views.append(slot_view)
		
	for index in range(slot_count):
		slot_views[index].setup(
			index,
			player_inventory.get_slot(index)
		)
		
		
		
		
		
		
		
		
		
		
