class_name PlayerAttack
extends Node

var player
var player_action
var player_equipment : PlayerEquipment
var player_interaction

@onready var tool_cast: ShapeCast2D = $"../ToolCast"
@onready var camera_2d: Camera2D = $"../Camera2D"

func setup(player_ref, action_ref, equipment_ref: PlayerEquipment, interaction_ref) -> void:
	player = player_ref
	player_action = action_ref
	player_equipment = equipment_ref
	player_interaction = interaction_ref
	
func request_attack() -> bool:
	if player_action.is_busy():
		return false
		
	var equipment := player_equipment.get_selected_equipment()
	
	if equipment == null:
		print("Nenhum equipmaneto selecionado.")
		return false
	
	print(
		"Usando equipmaneto: ",
		equipment.display_name
	)
	# Auto Face
	var auto_target := find_auto_target(equipment)
	
	if auto_target != null:
		var aim_position := auto_target.get_aim_position()
		player_interaction.face_position(aim_position)
		
	# Inicia a ação
	player_action.perform_equipment_action(equipment)
	
	return player_action.is_busy()
	
func configure_tool_cast(equipment: EquipmentData) -> void:
	var rectangle := tool_cast.shape as RectangleShape2D
	
	if rectangle == null:
		push_error("ToolCast precisa usar RectangleShape2D.")
		return
	
	var unique_rectangle := rectangle.duplicate() as RectangleShape2D
	tool_cast.shape = unique_rectangle
	unique_rectangle.size = equipment.hit_area_size
		
	var direction := get_facing_direction()
	
	tool_cast.position = direction * 4.0
	tool_cast.target_position = (
		direction * equipment.hit_distance
	)
	
	tool_cast.enabled = true
	
	print(
		"ToolCast | position: ",
		tool_cast.global_position,
		" | direção: ",
		direction,
		" | target_position: ",
		tool_cast.target_position,
		" | tamanho: ",
		unique_rectangle.size
	)
	
func get_mouse_cast_direction() -> Vector2:
	var mouse_position: Vector2 = player.get_global_mouse_position()
	
	var direction: Vector2 = (mouse_position - player.global_position)
	
	if direction.length_squared() <= 1.0:
		return get_facing_direction()
		
	return direction.normalized()
		
func get_facing_direction() -> Vector2:
	match player.facing:
		player.Facing.DOWN:
			return Vector2.DOWN
			
		player.Facing.UP:
			return Vector2.UP
			
		player.Facing.SIDE:
			if player.facing_left:
				return Vector2.LEFT
				
			return Vector2.RIGHT
		
	return Vector2.DOWN

func apply_equipment_hit(equipment: EquipmentData) -> void:
	if equipment == null:
		return
		
	print("PlayerAttack recebeu equipamento: ", equipment.display_name)
	
	configure_tool_cast(equipment)
	
	tool_cast.force_shapecast_update()
	print(
		"ShapeCast colisões: ",
		tool_cast.get_collision_count()
	)
	
	var target := find_closest_target()
	
	if target == null:
		print("Golpe sem alvo.")
		return
	
	print("Alvo encontrado: ", target.name)
	
	if target.has_method("receive_equipment_hit"):
		var hit_successful: bool = (
			target.receive_equipment_hit(
				player,
				equipment
			)
		)
		if hit_successful:
			camera_2d.shake()
			
	else:
		print(
			"O alvo não possui receive_equipment_hit(): ",
			target.name
		)
		
func find_closest_target() -> Node:
	var closest_target: Node = null
	var closest_distance := INF
	
	for index in range(tool_cast.get_collision_count()):
		var collider := tool_cast.get_collider(index)
		
		if not collider is HitArea:
			continue
			
		var target: Node = collider.get_target()
		
		if target == null:
			continue
			
		if not target is Node2D:
			continue
		
		var target_node := target as Node2D
		var distance : float = player.global_position.distance_squared_to(
			target_node.global_position
		)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_target = target
		
	return closest_target

func find_auto_target(equipment: EquipmentData) -> HitArea:
	if equipment == null:
		return null
		
	if not should_auto_face(equipment):
		return null
		
	var search_shape := CircleShape2D.new()
	
	var extra_reach := maxf(
		equipment.hit_area_size.x,
		equipment.hit_area_size.y
	) * 0.5
	
	search_shape.radius = (
		equipment.hit_distance
		+ extra_reach
		+ 4.0
	)
	
	var query := PhysicsShapeQueryParameters2D.new()
	
	query.shape = search_shape
	query.transform = Transform2D(0.0, player.global_position)
	
	# HitArea está na layer 8.
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var space_state : PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	
	var results : Array[Dictionary] = space_state.intersect_shape(query, 32)
	
	var closest_hit_area: HitArea = null
	var closest_distance:= INF
	
	for result in results:
		var collider = result.get("collider")
		
		if not collider is HitArea:
			continue
		
		var hit_area := collider as HitArea
		var target:= hit_area.get_target()
		
		if target == null:
			continue
			
		var aim_position := hit_area.get_aim_position()
		
		var distance : float = player.global_position.distance_squared_to(aim_position)
		
		if distance < closest_distance:
			closest_distance = distance
			closest_hit_area = hit_area
			
	return closest_hit_area
	
func should_auto_face(equipment: EquipmentData) -> bool:
	return (
		equipment != null
		and equipment.equipment_type == EquipmentData.EquipmentType.AXE
	)
	
func get_harvestable_at(cell: Vector2i) -> Node:
	var targeting: PlayerTargeting = player.player_targeting
	
	if not is_instance_valid(targeting.grid):
		return null
		
	return targeting.grid.get_harvestable(cell)
	
func can_hit_cell(cell: Vector2i, equipment: EquipmentData) -> bool:
	var target := get_harvestable_at(cell) as Harvestable
	
	return (
		target != null
		and target.can_receive_equipment_hit(equipment)
	)
	
func apply_locked_harvestable_hit(equipment: EquipmentData) -> void:
	var targeting: PlayerTargeting = player.player_targeting
	
	if not targeting.validate_locked_target():
		return
		
	var target := targeting.locked_target as Harvestable
	
	if target == null:
		return
		
	if target.receive_equipment_hit(player, equipment):
		camera_2d.shake()
	
	
