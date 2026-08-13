class_name FishingLine
extends Line2D


enum LineMode {
	HIDDEN,
	CASTING,
	WAITING,
	FIGHTING,
	RETURNING
}

@export_category("Returning Shape")
@export var returning_back_curve: float = 18.0
@export var returning_back_direction: Vector2 = Vector2.DOWN

@export_category("Shape")

@export_range(4, 32, 1)
var point_count: int = 12

@export var waiting_curve: float = 3.0
@export var casting_curve: float = 16.0
@export var fighting_curve: float = 5.0
@export var returning_curve: float = 12.0


@export_category("Wave")

@export var waiting_wave_amplitude: float = 0.8
@export var fighting_wave_amplitude: float = 5.0
@export var returning_wave_amplitude: float = 4.0

@export var waiting_wave_speed: float = 2.0
@export var fighting_wave_speed: float = 9.0
@export var returning_wave_speed: float = 10.0

@export var wave_frequency: float = 2.0


var start_position_provider: Callable
var end_position_provider: Callable

var mode: LineMode = LineMode.HIDDEN

var elapsed_time: float = 0.0
var cast_progress: float = 0.0
var return_progress: float = 0.0


func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO

	width = 1.0
	antialiased = false

	hide_line()


func setup(
	start_provider: Callable,
	end_provider: Callable
) -> void:
	start_position_provider = start_provider
	end_position_provider = end_provider


func _process(delta: float) -> void:
	if mode == LineMode.HIDDEN:
		return

	if not _providers_are_valid():
		hide_line()
		return

	elapsed_time += delta

	_update_line()


func set_mode(new_mode: LineMode) -> void:
	mode = new_mode

	if mode == LineMode.HIDDEN:
		hide_line()
		return

	visible = true

	match mode:
		LineMode.CASTING:
			cast_progress = 0.0

		LineMode.RETURNING:
			return_progress = 0.0


func set_cast_progress(value: float) -> void:
	cast_progress = clampf(value, 0.0, 1.0)


func set_return_progress(value: float) -> void:
	return_progress = clampf(value, 0.0, 1.0)


func hide_line() -> void:
	mode = LineMode.HIDDEN
	clear_points()
	visible = false


func _providers_are_valid() -> bool:
	return (
		start_position_provider.is_valid()
		and end_position_provider.is_valid()
	)


func _update_line() -> void:
	var start_global: Vector2 = start_position_provider.call()
	var end_global: Vector2 = end_position_provider.call()

	var start: Vector2 = to_local(start_global)
	var end: Vector2 = to_local(end_global)

	var difference: Vector2 = end - start
	var distance: float = difference.length()

	if distance <= 1.0:
		clear_points()
		return

	var direction: Vector2 = difference.normalized()
	var normal: Vector2 = direction.orthogonal()

	var curve_strength: float = _get_curve_strength(distance)
	var wave_amplitude: float = _get_wave_amplitude()
	var wave_speed: float = _get_wave_speed()

	var new_points := PackedVector2Array()

	for index in range(point_count + 1):
		var ratio: float = float(index) / float(point_count)

		var point: Vector2 = start.lerp(end, ratio)

		# Mantém as duas pontas presas.
		var endpoint_mask: float = sin(ratio * PI)

		var curve_offset: float = (
			endpoint_mask
			* curve_strength
		)

		var wave_offset: float = (
			sin(
				ratio * PI * wave_frequency
				+ elapsed_time * wave_speed
			)
			* wave_amplitude
			* endpoint_mask
		)

		point += normal * (
			curve_offset
			+ wave_offset
		)
		
		if mode == LineMode.RETURNING:
			point += _get_return_back_offset(
				ratio, return_progress, direction
			)

		new_points.append(point)

	points = new_points


func _get_curve_strength(distance: float) -> float:
	var distance_factor: float = clampf(
		distance / 80.0,
		0.25,
		1.5
	)

	match mode:
		LineMode.CASTING:
			# A curva cresce e diminui durante o lançamento.
			return (
				casting_curve
				* sin(cast_progress * PI)
				* distance_factor
			)

		LineMode.WAITING:
			return waiting_curve * distance_factor

		LineMode.FIGHTING:
			return fighting_curve * distance_factor

		LineMode.RETURNING:
			return (
				returning_curve
				* sin(return_progress * PI)
				* distance_factor
			)

	return 0.0


func _get_wave_amplitude() -> float:
	match mode:
		LineMode.WAITING:
			return waiting_wave_amplitude

		LineMode.FIGHTING:
			return fighting_wave_amplitude

		LineMode.RETURNING:
			return returning_wave_amplitude

	return 0.0


func _get_wave_speed() -> float:
	match mode:
		LineMode.WAITING:
			return waiting_wave_speed

		LineMode.FIGHTING:
			return fighting_wave_speed

		LineMode.RETURNING:
			return returning_wave_speed

	return 0.0

func _get_return_back_offset(
	ratio: float,
	progress: float,
	direction: Vector2
) -> Vector2:
	var backwards: Vector2 = -direction
	
	var return_mask: float = sin(progress * PI)
	var endpoint_mask: float = sin(ratio * PI)
	
	var rod_side_weight: float = pow(1.0 - ratio, 1.5)
	
	var strength: float = (
		returning_back_curve * return_mask * endpoint_mask * rod_side_weight
	)
	
	return backwards * strength
