extends Control

signal turn_left_requested
signal turn_right_requested

@onready var turn_left_button: Button = $TurnLeftButton
@onready var turn_right_button: Button = $TurnRightButton

func _ready() -> void:
	turn_left_button.pressed.connect(_on_left_button_pressed)
	turn_right_button.pressed.connect(_on_right_button_pressed)
	
func _on_left_button_pressed() -> void:
	turn_left_requested.emit()

func _on_right_button_pressed() -> void:
	turn_right_requested.emit()
