extends Control

signal edit_name_requested
signal body_requested
signal hair_requested
signal outfit_requested

@onready var name_label: Label = $NameLabel
@onready var edit_name_button: Button = $EditNameButton

@onready var body_button: Button = $VBoxContainer/BodyButton
@onready var hair_button: Button = $VBoxContainer/HairButton
@onready var outfit_button: Button = $VBoxContainer/OutfitButton

@onready var start_game_button: Button = $StartGameButton
@onready var random_button: Button = $RandomButton

func _ready() -> void:
	edit_name_button.pressed.connect(_on_edit_name_pressed)
	body_button.pressed.connect(_on_body_pressed)
	hair_button.pressed.connect(_on_hair_pressed)
	outfit_button.pressed.connect(_on_outfit_pressed)
	
func set_nickname(nickname: String) -> void:
	name_label.text = nickname

func _on_edit_name_pressed() -> void:
	edit_name_requested.emit()
	
func _on_body_pressed() -> void:
	body_requested.emit()
	
func _on_hair_pressed() -> void:
	hair_requested.emit()

func _on_outfit_pressed() -> void:
	outfit_requested.emit()


	
	
