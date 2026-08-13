extends Camera2D

@export_category("Zoom")
@export var zoom_step: float = 0.1
@export var zoom_speed: float = 8.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_toward_mouse: bool = true

var target_zoom: Vector2


func _ready() -> void:
	target_zoom = zoom


func _process(delta: float) -> void:
	zoom = zoom.lerp(
		target_zoom,
		min(zoom_speed * delta, 1.0)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		apply_zoom(zoom_step)

	if event.is_action_pressed("zoom_out"):
		apply_zoom(-zoom_step)


func apply_zoom(amount: float) -> void:
	var old_mouse_position := get_global_mouse_position()

	var new_zoom_value : float = clamp(
		target_zoom.x + amount,
		min_zoom,
		max_zoom
	)

	target_zoom = Vector2(
		new_zoom_value,
		new_zoom_value
	)

	if zoom_toward_mouse:
		zoom = target_zoom

		var new_mouse_position := get_global_mouse_position()
		global_position += old_mouse_position - new_mouse_position
