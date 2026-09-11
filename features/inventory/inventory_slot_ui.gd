class_name InventorySlotUI
extends Control

@export var empty_background: Texture2D
@export var occupied_background: Texture2D

@onready var background: TextureRect = $Background
@onready var item_icon: TextureRect = $ItemIcon
@onready var amount_label: Label = $AmountLabel
@onready var selection_border: TextureRect = $SelectionBorder

var slot_index: int = 1
var inventory_slot: InventorySlot

func _ready() -> void:
	refresh()
	
func setup(index: int, slot: InventorySlot) -> void:
	slot_index = index
	inventory_slot = slot
	refresh()
	
func refresh() -> void:
	if inventory_slot == null or inventory_slot.is_empty():
		background.texture = empty_background
		item_icon.texture = null
		amount_label.text = ""
		amount_label.hide()
		return
		
	background.texture = occupied_background
	item_icon.texture = inventory_slot.item.icon
	
	amount_label.text = str(inventory_slot.amount)
	amount_label.visible = inventory_slot.amount > 1
	
func set_selected(value: bool) -> void:
	selection_border.visible = value
