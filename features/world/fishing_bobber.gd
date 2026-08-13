class_name FishingBobber
extends Node2D

signal landed(position: Vector2)
signal removed

@export_category("Throw")
@export var throw_duration: float = 0.35
@export var arc_height: float = 18.0

@export_category("Return")
@export var default_return_duration: float = 0.40

@export var return_arc_height: float = 28.0
@export var return_target_height: float = 0.0

@onready var bobber_sprite: Sprite2D = $BobberSprite
@onready var fishing_line: FishingLine = $FishingLine
@onready var detection_area: Area2D = $DetectionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var rod_tip_position_provider: Callable
var return_target_provider: Callable

var start_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var throw_elapsed: float = 0.0
var is_throwing: bool = false

var return_start_position: Vector2 = Vector2.ZERO
var return_duration: float = 0.40
var return_elapsed: float = 0.0
var is_returning: bool = false

var is_landed: bool = false

func _ready() -> void:
	visible = false

func setup(position_provider: Callable) -> void:
	rod_tip_position_provider = position_provider

	fishing_line.setup(
		rod_tip_position_provider,
		Callable(self, "get_line_end_position")
	)

func _process(delta: float) -> void:
	if is_throwing:
		_update_throw(delta)
		return

	if is_returning:
		_update_returning(delta)

# THROW
func throw_to(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	start_position = from_position
	target_position = to_position

	global_position = start_position
	visible = true

	throw_elapsed = 0.0

	is_throwing = true
	is_returning = false
	is_landed = false

	_set_detection_enabled(false)

	fishing_line.set_mode(
		FishingLine.LineMode.CASTING
	)


func _update_throw(delta: float) -> void:
	if throw_duration <= 0.0:
		global_position = target_position
		_finish_throw()
		return

	throw_elapsed += delta

	var progress: float = clampf(
		throw_elapsed / throw_duration,
		0.0,
		1.0
	)

	var base_position: Vector2 = start_position.lerp(
		target_position,
		progress
	)

	var arc_offset: float = (
		sin(progress * PI)
		* arc_height
	)

	global_position = (
		base_position
		+ Vector2.UP * arc_offset
	)

	fishing_line.set_cast_progress(progress)

	if progress >= 1.0:
		_finish_throw()


func _finish_throw() -> void:
	is_throwing = false
	is_landed = true

	global_position = target_position

	_set_detection_enabled(true)

	fishing_line.set_mode(
		FishingLine.LineMode.WAITING
	)

	landed.emit(global_position)


# RETURN
func start_returning(
	target_provider: Callable,
	duration: float = -1.0
) -> void:
	if not target_provider.is_valid():
		remove_bobber()
		return

	return_target_provider = target_provider

	if duration > 0.0:
		return_duration = duration
	else:
		return_duration = default_return_duration
	
	return_duration = maxf(
		return_duration,
		0.01
	)
	
	return_start_position = global_position
	return_elapsed = 0.0
	
	is_throwing = false
	is_landed = false
	is_returning = true
	
	_set_detection_enabled(false)
	
	fishing_line.set_mode(
		FishingLine.LineMode.RETURNING
	)

func _update_returning(delta: float) -> void:
	if not return_target_provider.is_valid():
		remove_bobber()
		return

	return_elapsed += delta

	var progress: float = clampf(
		return_elapsed / return_duration,
		0.0,
		1.0
	)

	var eased_progress: float = smoothstep(
		0.0,
		1.0,
		progress
	)

	var current_target: Vector2 = (
		return_target_provider.call()
	)
	
	current_target.y += return_target_height
	
	var base_position: Vector2 = return_start_position.lerp(
		current_target, eased_progress
	)
	
	var arc_offset: float = (
		sin(progress * PI) * return_arc_height
	)
	
	global_position = (
		base_position
		+ Vector2.UP * arc_offset
	)

	fishing_line.set_return_progress(progress)

	if progress >= 1.0:
		global_position = current_target
		remove_bobber()

# LINE MODES
func set_line_waiting() -> void:
	if not is_instance_valid(fishing_line):
		return

	fishing_line.set_mode(
		FishingLine.LineMode.WAITING
	)


func set_line_fighting() -> void:
	if not is_instance_valid(fishing_line):
		return

	fishing_line.set_mode(
		FishingLine.LineMode.FIGHTING
	)


# HELPERS
func get_line_end_position() -> Vector2:
	return global_position


func _set_detection_enabled(enabled: bool) -> void:
	if detection_area == null:
		return

	detection_area.monitoring = enabled
	detection_area.monitorable = enabled

	var collision_shape := (
		detection_area.get_node_or_null("CollisionShape2D")
		as CollisionShape2D
	)

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			not enabled
		)


func remove_bobber() -> void:
	if is_queued_for_deletion():
		return

	is_throwing = false
	is_returning = false
	is_landed = false

	_set_detection_enabled(false)

	if is_instance_valid(fishing_line):
		fishing_line.hide_line()

	removed.emit()

	queue_free()
