class_name BodyMenu
extends Control

signal skin_color_requested
signal eye_color_requested
signal confirm_requested

signal body_type_requested(body_type : int)

@onready var type_1_button: Button = $BodyTypes/Type1Button
@onready var type_2_button: Button = $BodyTypes/Type2Button

@onready var skin_color_button: Button = $SkinColorButton
@onready var eye_color_button: Button = $EyeColorButton
@onready var confirm_button: Button = $ConfirmButton

func _ready() -> void:
	type_1_button.pressed.connect(_on_type_1_pressed)
	type_2_button.pressed.connect(_on_type_2_pressed)
	
	skin_color_button.pressed.connect(_on_skin_color_pressed)
	eye_color_button.pressed.connect(_on_eye_color_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_type_1_pressed() -> void:
	body_type_requested.emit(1)

func _on_type_2_pressed() -> void:
	body_type_requested.emit(2)
	
func _on_skin_color_pressed() -> void:
	skin_color_requested.emit()

func _on_eye_color_pressed() -> void:
	eye_color_requested.emit()
	
func _on_confirm_pressed() -> void:
	confirm_requested.emit()
	
