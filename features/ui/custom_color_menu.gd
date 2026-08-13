class_name CustomColorMenu
extends Control

signal color_selected(color: Color)
signal confirm_requested

@onready var custom_color_title: Label = $CustomColorTitle
@onready var color_picker: ColorPicker = $PresetGrid/ColorPicker
@onready var confirm_button: Button = $ConfirmButton

var selected_color: Color = Color.WHITE

func _ready() -> void:
	color_picker.color_changed.connect(_on_color_changed)
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	
func open_custom_color_menu(
	title: String,
	current_color: Color
) -> void:
	custom_color_title.text = title
	
	selected_color = current_color
	color_picker.color = current_color
	
	show()
	
func _on_color_changed(color: Color) -> void:
	selected_color = color
	
	color_selected.emit(color)

func _on_confirm_pressed() -> void:
	confirm_requested.emit()
	
	
