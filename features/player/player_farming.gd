class_name PlayerFarming
extends Node

var player
var tool_utils : PlayerToolUtils
var farming_map: FarmingMap

@export var starting_seed_package: SeedItemData
var selected_seed_stack: SeedStack

# Armazenamento provisório dos produtos colhidos.
var harvested_items: Dictionary = {}

func _ready() -> void:
	if starting_seed_package != null:
		selected_seed_stack = SeedStack.new(starting_seed_package)
	
func setup(player_ref, tool_utils_ref) -> void:
	player = player_ref
	tool_utils = tool_utils_ref

func set_farming_map(value: FarmingMap) -> void:
	farming_map = value

func get_targeting() -> PlayerTargeting:
	return player.player_targeting

func has_farming_context() -> bool:
	return (
		is_instance_valid(farming_map)
		and is_instance_valid(get_targeting().grid)
	)

func to_farming_cell(cell: Vector2i) -> Vector2i:
	var world_position := get_targeting().grid.cell_to_world(cell)
	return farming_map.world_to_cell(world_position)

func is_resource_blocking(cell: Vector2i) -> bool:
	return get_targeting().grid.get_harvestable(cell) != null
	
	
func can_till(cell: Vector2i) -> bool:
	if not has_farming_context():
		return false
	
	if is_resource_blocking(cell):
		return false
	
	var farm_cell := to_farming_cell(cell)
	
	if not farming_map.is_farmable(farm_cell):
		return false
		
	if farming_map.get_crop(farm_cell) != null:
		return false
		
	var data := farming_map.get_cell_data(farm_cell)
	
	return data["state"] != FarmingMap.SoilState.TILLED

func can_water(cell: Vector2i) -> bool:
	if not has_farming_context():
		return false
		
	if is_resource_blocking(cell):
		return false
	
	var farm_cell := to_farming_cell(cell)
	
	if not farming_map.is_farmable(farm_cell):
		return false
		
	var data := farming_map.get_cell_data(farm_cell)
	
	return (
		data["state"] == FarmingMap.SoilState.TILLED
		and not data["watered"]
	)

func can_plant(cell: Vector2i) -> bool:
	if not has_farming_context():
		return false
		
	if selected_seed_stack == null:
		return false
	
	if not selected_seed_stack.can_plant():
		return false
	
	if is_resource_blocking(cell):
		return false
	
	return farming_map.can_plant(to_farming_cell(cell))

func get_crop_at(cell: Vector2i) -> Node:
	if not has_farming_context():
		return null
		
	return farming_map.get_crop(to_farming_cell(cell))

func can_collect(cell: Vector2i) -> bool:
	var crop := get_crop_at(cell) as Crop
	
	if crop == null or crop.is_queued_for_deletion():
		return false
		
	return crop.is_ready_to_harvest() or crop.is_rotten()

func till_ground(_equipment: EquipmentData) -> void:
	var targeting := get_targeting()
	
	if not targeting.has_locked_target:
		return
		
	var cell := targeting.locked_target_cell
	
	if targeting.validate_locked_target() and can_till(cell):
		farming_map.till_cell(to_farming_cell(cell))

func water_ground(_equipment: EquipmentData) -> void:
	var targeting := get_targeting()
	
	if not targeting.has_locked_target:
		return
	
	var cell := targeting.locked_target_cell
	
	if targeting.validate_locked_target() and can_water(cell):
		farming_map.water_cell(to_farming_cell(cell))

func try_plant_selected() -> bool:
	if player.player_action.is_busy() or player.player_fishing.is_active():
		return false
	
	var targeting := get_targeting()
	
	if not targeting.lock_target(Callable(self, "can_plant")):
		return false
	
	var planted := farming_map.plant_crop(
		to_farming_cell(targeting.locked_target_cell),
		selected_seed_stack.item.crop_data
	)
	
	if planted:
		selected_seed_stack.remaining -= 1
		
	targeting.unlock_target()
	return planted

func try_start_crop_collection() -> bool:
	if player.player_action.is_busy() or player.player_fishing.is_active():
		return false
	
	var targeting := get_targeting()
	
	if not targeting.lock_target(
		Callable(self, "can_collect"),
		Callable(self, "get_crop_at")
	):
		return false
		
	player.player_action.perform_action(
		ActionType.Type.COLLECTING,
		targeting.locked_target
	)
	
	return true

func collect_crop(crop: Crop) -> void:
	var targeting := get_targeting()
	
	if not targeting.validate_locked_target():
		return
		
	if not is_instance_valid(crop):
		return
	
	if targeting.locked_target != crop:
		return
	
	var farm_cell := to_farming_cell(targeting.locked_target_cell)
	
	if crop.is_rotten():
		farming_map.clear_rotten_crop(farm_cell)
	else:
		farming_map.harvest_crop(
			farm_cell,
			Callable(self, "receive_harvest")
		)

func receive_harvest(item_id: StringName, amount: int) -> bool:
	harvested_items[item_id] = (
		int(harvested_items.get(item_id, 0)) + amount
	)
	
	return true
	
func _can_use_farming_tool(equipment: EquipmentData) -> bool:
	if equipment == null:
		return false
		
	if tool_utils == null:
		return false
	
	if farming_map == null:
		return false
	
	return true

func _get_target_position(equipment: EquipmentData) -> Vector2:
	return tool_utils.get_target_position(equipment.hit_distance)
	
