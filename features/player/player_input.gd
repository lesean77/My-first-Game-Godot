extends Node

func get_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	return direction.normalized()

func wants_attack() -> bool:
	return Input.is_action_just_pressed("attack")

func wants_interact() -> bool:
	return Input.is_action_just_pressed("interact")
	
func wants_next_tool() -> bool:
	var pressed := Input.is_action_just_pressed("next_tool")
	if pressed:
		print("Input Detectado: next_tool")
		
	return pressed

func wants_previous_tool() -> bool:
	var pressed := Input.is_action_just_pressed("previous_tool")
	if pressed:
		print("Input Detectado: previous_tool")
		
	return pressed

func wants_cancel_action() -> bool: 
	return Input.is_action_just_pressed("cancel_action")
	
func is_attack_pressed() -> bool:
	return Input.is_action_pressed("attack")
	
func released_attack() -> bool:
	return Input.is_action_just_released("attack")
