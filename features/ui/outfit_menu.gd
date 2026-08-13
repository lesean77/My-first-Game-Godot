class_name OutfitMenu
extends Control

signal outfit_requested(outfit_id: int)
signal confirm_requested

@onready var scroll_container: ScrollContainer = $ClothesGrid/ScrollContainer
@onready var grid_container: GridContainer = $ClothesGrid/ScrollContainer/GridContainer
@onready var selection_frame: NinePatchRect = $ClothesGrid/SelectionFrame

@onready var button_template: TextureButton = $ClothesGrid/ScrollContainer/GridContainer/OutfitButton

@onready var confirm_button: Button = $ConfirmButton

var available_outfits: Array[OutfitData] = []
var current_body_type: int = 1

var buttons_by_id: Dictionary = {}

var selected_button: TextureButton = null
var selected_outfit_id: int = -1

func _ready() -> void:
	selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_frame.hide()
	
	button_template.hide()
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	
func _clear_outfit_buttons() -> void:
	buttons_by_id.clear()
	
	selected_button = null
	selected_outfit_id = -1
	
	selection_frame.hide()
	
	for child in grid_container.get_children():
		if child == button_template:
			continue
		
		grid_container.remove_child(child)
		child.queue_free()

func setup_outfit_options(outfit_options: Array[OutfitData]) -> void:
	available_outfits = outfit_options

func set_body_type(body_type: int) -> void:
	if current_body_type == body_type and not buttons_by_id.is_empty():
		return
		
	current_body_type = body_type
	
	_rebuild_outfit_grid()
	
func _rebuild_outfit_grid() -> void:
	_clear_outfit_buttons()
	
	for outfit_data in available_outfits:
		if outfit_data == null:
			continue
			
		_create_outfit_button(outfit_data, current_body_type)
		
func _create_outfit_button(outfit_data: OutfitData, body_type: int) -> void:
	if buttons_by_id.has(outfit_data.id):
		push_warning(
			"OutfitMenu: OutfitData com ID Duplicado: %s" % outfit_data.id
		)
		return
	
	var button := button_template.duplicate() as TextureButton
	
	button.name = "OutfitButton_%s" % outfit_data.id
	
	var icon := button.get_node("OutfitIcon") as TextureRect
	
	icon.texture = outfit_data.get_icon_for_body(body_type)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	grid_container.add_child(button)
	
	buttons_by_id[outfit_data.id] = button
	
	button.pressed.connect(
		_on_outfit_button_pressed.bind(
			outfit_data.id,
			button
		)
	)
	
	button.show()
	
func _on_outfit_button_pressed(
	outfit_id: int,
	button: TextureButton
) -> void:
	selected_outfit_id = outfit_id
	selected_button = button
	
	_refresh_selection_frame()
	
	outfit_requested.emit(outfit_id)	

func set_selected_outfit(outfit_id: int) -> void:
	if not buttons_by_id.has(outfit_id):
		return
		
	selected_outfit_id = outfit_id
	selected_button = buttons_by_id[outfit_id] as TextureButton
	
	call_deferred("_refresh_selection_frame")
	
func _refresh_selection_frame() -> void:
	if selected_button == null:
		selection_frame.hide()
		return
		
	selection_frame.show()
		
	selection_frame.global_position = selected_button.global_position
	selection_frame.size = selected_button.size
	

func _on_scroll_changed(_value: float) -> void:
	_refresh_selection_frame()


func _on_confirm_pressed() -> void:
	confirm_requested.emit()
	
