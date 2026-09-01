extends Camera2D

@export_category("Zoom")
@export var zoom_step: float = 0.1
@export var zoom_speed: float = 8.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0
@export var zoom_toward_mouse: bool = true

@export_category("Camera Shake")
# Intensidade padrão caso shake() seja chamado sem valor.
@export var default_shake_intensity: float = 2.0

# Duração padrão
@export var default_shake_duration: float = 0.15

# Velocidade com que percorremos o noise.
@export var shake_noise_speed: float = 40.0

var target_zoom: Vector2

var camera_shake_noise: FastNoiseLite
var shake_tween: Tween

var shake_time: float = 0.0
var current_shake_intensity: float = 0.0

var base_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	target_zoom = zoom
	print(get_path())
	
	camera_shake_noise = FastNoiseLite.new()
	camera_shake_noise.seed = randi()

func _process(delta: float) -> void:
	zoom = zoom.lerp(
		target_zoom,
		min(zoom_speed * delta, 1.0)
	)
	
	_update_camera_shake(delta)

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
		
func shake(intensity: float = -1.0, duration: float = -1.0) -> void:
	if intensity < 0.0:
		intensity = default_shake_intensity
	
	if duration < 0.0:
		duration = default_shake_duration
		
	# Se outro shake ainda estiver acontecendo, interrompemos e começamos o novo.
	if shake_tween != null:
		shake_tween.kill()
	
	shake_time = 0.0
	current_shake_intensity = intensity
	
	shake_tween = create_tween()
	
	shake_tween.tween_method(
		_set_shake_intensity,
		intensity,
		0.0,
		duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)
	
	shake_tween.tween_callback(_finish_camera_shake)
	
func _set_shake_intensity(intensity: float) -> void:
	current_shake_intensity = intensity
	
func _update_camera_shake(delta: float) -> void:
	if current_shake_intensity <= 0.0:
		return
	
	shake_time += (
		delta * shake_noise_speed
	)
	
	var noise_x: float = (
		camera_shake_noise.get_noise_1d(shake_time)
	)
	
	var noise_y: float = (
		camera_shake_noise.get_noise_1d(shake_time + 1000.0)
	)
	
	offset = (
		base_offset
		+ Vector2(noise_x, noise_y) * current_shake_intensity
	)

func _finish_camera_shake() -> void:
	current_shake_intensity = 0.0
	offset = base_offset
	
	
