extends Control

signal nickname_confirmed(nickname : String)

@onready var nickname_edit: LineEdit = $Panel/NicknameEdit
@onready var confirm_button: Button = $Panel/ConfirmButton
@onready var error_label: Label = $Panel/ErrorLabel

var previous_nickname: String = ""

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	nickname_edit.text_submitted.connect(_on_text_submitted)
	
func open(current_nickname: String = "") -> void:
	previous_nickname = current_nickname
	
	show()
	
	error_label.hide()
	nickname_edit.text = current_nickname
	
	nickname_edit.call_deferred("grab_focus")
	nickname_edit.call_deferred("select_all")
	
func _on_confirm_pressed() -> void:
	confirm_nickname()
	
func _on_text_submitted(_text: String) -> void:
	confirm_nickname()
	
func confirm_nickname() -> void:
	var nickname := nickname_edit.text.strip_edges()
	
	if nickname.is_empty() and not previous_nickname.is_empty():
		nickname_confirmed.emit(previous_nickname)
		return
	
	if nickname.is_empty():
		show_error("Por favor entre com um apelido.")
		return
		
	nickname_confirmed.emit(nickname)
	
func show_error(message: String) -> void:
	error_label.text = message
	error_label.show()
	
	
	
