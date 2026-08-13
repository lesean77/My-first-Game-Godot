class_name HairMenu
extends Control

signal hair_requested(hair_id: int)
signal hair_color_requested
signal confirm_requested
signal accessory_color_requested

@onready var scroll_container: ScrollContainer = $HairGrid/ScrollContainer
@onready var grid_container: GridContainer = $HairGrid/ScrollContainer/GridContainer
@onready var selection_frame: NinePatchRect = $HairGrid/SelectionFrame

@onready var button_template: TextureButton = $HairGrid/ScrollContainer/GridContainer/HairButton

@onready var hair_color_button: Button = $HairColorButton
@onready var accessory_color_button: Button = $AccessoryColorButton

@onready var confirm_button: Button = $ConfirmButton

var buttons_by_id: Dictionary = {}

var selected_button: TextureButton = null
var selected_hair_id: int = -1

func _ready() -> void:
	selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_frame.hide()
	
	button_template.hide()
	accessory_color_button.hide()
	
	hair_color_button.pressed.connect(_on_hair_color_pressed)
	accessory_color_button.pressed.connect(_on_accessory_color_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	
func _clear_hair_buttons() -> void:
	buttons_by_id.clear()
	
	selected_button = null
	selected_hair_id = -1
	
	selection_frame.hide()
	
	for child in grid_container.get_children():
		if child == button_template:
			continue
			
		child.queue_free()

func setup_hair_options(hair_options: Array[HairData]) -> void:
	_clear_hair_buttons()
	
	for hair_data in hair_options:
		if hair_data == null:
			continue
		
		_create_hair_button(hair_data)
		
func _create_hair_button(hair_data: HairData) -> void:
	if buttons_by_id.has(hair_data.id):
		push_warning(
			"HairMenu: HairData com ID duplicado: %s" % hair_data.id
		)
		
		return
	
	var button := button_template.duplicate() as TextureButton
	
	button.name = "HairButton_%s" % hair_data.id
	
	var icon := button.get_node("HairIcon") as TextureRect
	
	icon.texture = hair_data.icon
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	grid_container.add_child(button)
	
	buttons_by_id[hair_data.id] = button
	
	button.pressed.connect(
		_on_hair_button_pressed.bind(
			hair_data.id,
			button
		)
	)
	
	button.show()
	
func _on_hair_button_pressed(
	hair_id: int,
	button: TextureButton
) -> void:
	selected_hair_id = hair_id
	selected_button = button
	
	_refresh_selection_frame()
	
	hair_requested.emit(hair_id)
	
func set_selected_hair(hair_id: int) -> void:
	if not buttons_by_id.has(hair_id):
		return
	
	selected_hair_id = hair_id
	selected_button = buttons_by_id[hair_id] as TextureButton
	
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
	
func _on_hair_color_pressed() -> void:
	hair_color_requested.emit()

func _on_accessory_color_pressed() -> void:
	accessory_color_requested.emit()
	
func _on_confirm_pressed() -> void:
	confirm_requested.emit()

func _set_color_button_preview(
	button: Button,
	color: Color
) -> void:
	var normal := (
		button
		.get_theme_stylebox("normal")
		.duplicate() as StyleBoxFlat
	)
	
	var hover := (
		button
		.get_theme_stylebox("hover")
		.duplicate() as StyleBoxFlat
	)
	
	var pressed := (
		button
		.get_theme_stylebox("pressed")
		.duplicate() as StyleBoxFlat
	)
	
	normal.bg_color = color
	hover.bg_color = color.lightened(0.10)
	pressed.bg_color = color.darkened(0.10)
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	
func set_hair_color_preview(color: Color) -> void:
	_set_color_button_preview(
		hair_color_button,
		color
	)

func set_accessory_color_preview(color: Color) -> void:
	_set_color_button_preview(
		accessory_color_button,
		color
	)

func set_accessory_available(has_accessory: bool) -> void:
	accessory_color_button.visible = has_accessory
