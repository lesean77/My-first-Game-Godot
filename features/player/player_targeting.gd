class_name PlayerTargeting
extends Node

var player
var grid: WorldGrid
var indicator: TargetIndicator

var has_locked_target: bool = false
var locked_target_cell: Vector2i
var locked_target: Node = null

var _locked_validator: Callable
var _locked_resolver: Callable

func setup(player_ref, indicator_ref: TargetIndicator) -> void:
	player = player_ref
	indicator = indicator_ref
	
func set_grid(value: WorldGrid) -> void:
	unlock_target()
	grid = value

func get_target_cell() -> Vector2i:
	return grid.get_target_cell(
		player.global_position,
		player.get_global_mouse_position(),
		player.player_tools_utils.get_facing_direction()
	)

func update_preview(validator: Callable) -> void:
	if indicator == null:
		return
	
	if not is_instance_valid(grid):
		indicator.hide_target()
		return
	
	if (
		player.player_action.is_busy()
		or player.player_fishing.is_active()
		or not validator.is_valid()
	):
		indicator.hide_target()
		return
	
	var cell := get_target_cell()
	var valid: bool = validator.call(cell)
	
	indicator.show_target(
		grid.cell_to_world(cell),
		valid,
		false
	)

func lock_target(validator: Callable, resolver: Callable = Callable()) -> bool:
	if has_locked_target:
		return false
	
	if not is_instance_valid(grid) or not validator.is_valid():
		return false
		
	var cell := get_target_cell()
	var valid: bool = validator.call(cell)
	
	if not valid:
		return false
	
	var target: Node = null
	
	if resolver.is_valid():
		target = resolver.call(cell)
		
		if not is_instance_valid(target):
			return false
		
	locked_target_cell = cell
	locked_target = target
	_locked_validator = validator
	_locked_resolver = resolver
	has_locked_target = true
	
	player.player_interaction.face_position(grid.cell_to_world(cell))
	
	indicator.show_target(
		grid.cell_to_world(cell),
		true, true
	)
	
	return true
	
func validate_locked_target() -> bool:
	if not has_locked_target or not is_instance_valid(grid):
		return false
		
	if not _locked_validator.is_valid():
		return false
		
	var valid: bool = _locked_validator.call(locked_target_cell)
	
	if not valid:
		return false
		
	if _locked_resolver.is_valid():
		if not is_instance_valid(locked_target):
			return false
		
		if locked_target.is_queued_for_deletion():
			return false
		
		var current: Node = _locked_resolver.call(locked_target_cell)
		
		if current != locked_target:
			return false
			
	return true
	
func unlock_target() -> void:
	has_locked_target = false
	locked_target = null
	_locked_validator = Callable()
	_locked_resolver = Callable()
	
	if indicator != null:
		indicator.hide_target()
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
