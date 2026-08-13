class_name Colormenu
extends Control

signal color_selected(color: Color)
signal confirm_requested
signal custom_color_requested

@onready var predefined_colors: GridContainer = $PresetGrid/GridContainer
@onready var color_button_template: Button = $PresetGrid/GridContainer/ColorButtonTemplate

@onready var color_title: Label = $ColorTitle

@onready var confirm_button: Button = $ConfirmButton
@onready var custom_color_button: Button = $PresetGrid/CustomColorButton

var selected_color: Color = Color("#4CB528")

func _ready() -> void:
	if not confirm_button.pressed.is_connected(_on_confirm_pressed):
		confirm_button.pressed.connect(_on_confirm_pressed)
		
	if not custom_color_button.pressed.is_connected(_on_custom_color_pressed):
		custom_color_button.pressed.connect(_on_custom_color_pressed)
		
func open_color_menu(
	title: String,
	colors: Dictionary[String, Color],
	current_color: Color
)-> void:
	color_title.text = title
	selected_color = current_color
	
	create_color_buttons(colors)
	
	set_custom_color_preview(current_color)
	
	show()
	
func create_color_buttons(colors: Dictionary) -> void:
	for child in predefined_colors.get_children():
		if child != color_button_template:
			child.queue_free()
			
	for color_name: String in colors:
		var color: Color = colors[color_name]
		
		var button := color_button_template.duplicate() as Button
		
		button.name = color_name.to_pascal_case() + "Button"
		button.visible = true
		
		set_button_color(button, color)
		
		button.pressed.connect(
			_on_predefined_color_pressed.bind(color)
		)
		
		predefined_colors.add_child(button)

func set_button_color(button: Button, color: Color) -> void:
	var normal := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	var hover := button.get_theme_stylebox("hover").duplicate() as StyleBoxFlat
	var pressed := button.get_theme_stylebox("pressed").duplicate() as StyleBoxFlat
	
	normal.bg_color = color
	hover.bg_color = color.lightened(0.10)
	pressed.bg_color = color.darkened(0.10)
	
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	
func _on_predefined_color_pressed(color : Color) -> void:
	selected_color = color
	
	set_custom_color_preview(color)
	
	color_selected.emit(color)

func _on_confirm_pressed() -> void:
	confirm_requested.emit()

func _on_custom_color_pressed() -> void:
	custom_color_requested.emit()

func set_custom_color_preview(color: Color) -> void:
	var normal := (
		custom_color_button
		.get_theme_stylebox("normal")
		.duplicate() as StyleBoxFlat
	)
	
	var hover := (
		custom_color_button
		.get_theme_stylebox("hover")
		.duplicate() as StyleBoxFlat
	)
	
	var pressed := (
		custom_color_button
		.get_theme_stylebox("pressed")
		.duplicate() as StyleBoxFlat
	)
	
	normal.bg_color = color
	hover.bg_color = color.lightened(0.10)
	pressed.bg_color = color.darkened(0.10)
	
	custom_color_button.add_theme_stylebox_override("normal", normal)
	custom_color_button.add_theme_stylebox_override("hover", hover)
	custom_color_button.add_theme_stylebox_override("pressed",pressed)
