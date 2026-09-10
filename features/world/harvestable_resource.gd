class_name Harvestable 
extends StaticBody2D

@export var data : HarvestableData
@export var outline_sprite: Sprite2D

@export_range(0.0, 10.0, 0.5) var hit_shake_distance: float = 1.5

var _hit_shake_tween: Tween

var current_health : int

var world_grid: WorldGrid
var occupied_cell: Vector2i
var registered_on_grid: bool = false

var _destroyed: bool = false


var _outline_material: ShaderMaterial

func _ready() -> void:
	if data == null:
		push_error("Varvestable sem HarvestableData: " + name)
		return
		
	setup_outline()
	
	current_health = data.max_health
	
	register_on_grid()

func setup_outline() -> void:
	if outline_sprite == null:
		return
		
	var source := outline_sprite.material as ShaderMaterial
	
	if source == null:
		return
		
	_outline_material = source.duplicate() as ShaderMaterial
	outline_sprite.material = _outline_material
	
	set_target_highlight(false)
	set_shake_offset(0.0)

func set_target_highlight(enabled: bool) -> void:
	if _outline_material == null:
		return
	
	_outline_material.set_shader_parameter("outline_enabled", enabled)


func set_shake_offset(value: float) -> void:
	if _outline_material == null:
		return
		
	_outline_material.set_shader_parameter("shake_offset", value)

func get_target_world_position() -> Vector2:
	return to_global(data.target_offset)

func register_on_grid() -> void:
	world_grid = find_world_grid()
	
	if world_grid == null or world_grid.reference_layer == null:
		push_warning("Harvestable sem WorldGrid: " + name)
		return
		
	occupied_cell = world_grid.world_to_cell(get_target_world_position())
	
	registered_on_grid = world_grid.register_harvestable(occupied_cell, self)

func unregister_from_grid() -> void:
	if registered_on_grid and is_instance_valid(world_grid):
		world_grid.unregister_harvestable(occupied_cell, self)
		
	registered_on_grid = false

func find_world_grid() -> WorldGrid:
	var ancestor := get_parent()
	
	while ancestor != null:
		var candidate := ancestor.get_node_or_null("WorldGrid")
		
		if candidate is WorldGrid:
			return candidate as WorldGrid
		
		ancestor = ancestor.get_parent()
		
	return null
	
func get_action_type() -> ActionType.Type:
	if data == null:
		return ActionType.Type.NONE
	
	return data.action_type

func can_receive_equipment_hit(equipment: EquipmentData) -> bool:
	return (
		data != null
		and equipment != null
		and current_health > 0
		and not is_queued_for_deletion()
		and equipment.action_type == data.action_type
	)

func receive_equipment_hit(player: Node, equipment: EquipmentData) -> bool:
	if not can_receive_equipment_hit(equipment):
		return false
	
	var damage: int = maxi(equipment.damage, 1)
	current_health = maxi(current_health - damage, 0)
	
	print(
		data.display_name, 
		" recebeu ",
		damage,
		" de dano. Vida: ",
		current_health,
		"/",
		data.max_health
	)
	
	try_drop_hit_fragments()
	
	if current_health <= 0:
		shake_camera_on_destruction(player)
		destroy_resource()
	else:
		play_hit_shake()
		
	return true

func shake_camera_on_destruction(player: Node) -> void:
	if not is_instance_valid(player):
		return
	
	var attack := player.get_node_or_null("PlayerAttack")
	
	if attack != null and attack.has_method("shake_camera"):
		attack.shake_camera()
	
func destroy_resource() -> void:
	if _destroyed:
		return
	
	_destroyed = true
	unregister_from_grid()
	
	spawn_destruction_effect()
	
	if data != null:
		var amount := randi_range(
			data.drop_amount_min,
			data.drop_amount_max
		)
	
		if amount > 0 and not data.drop_item_id.is_empty():
			spawn_drop(data.drop_item_id, amount)
	
		print(data.display_name, " foi destruído.")
		
	queue_free()
	
func try_drop_hit_fragments() -> void:
	if data.hit_drop_item_id.is_empty():
		return
		
	if not RandomUtils.roll_percent(data.hit_drop_chance):
		return
		
	var amount := RandomUtils.random_amount(
		data.hit_drop_amount_min,
		data.hit_drop_amount_max
	)
	
	if amount <= 0:
		return
	
	spawn_drop(data.hit_drop_item_id, amount)

func spawn_drop(item_id: StringName, amount: int) -> void:
	print("Drop gerado: ", amount, "x ", item_id)

func _exit_tree() -> void:
	unregister_from_grid()
	
func play_hit_shake() -> void:
	if _outline_material == null:
		return
		
	if _hit_shake_tween != null and _hit_shake_tween.is_valid():
		_hit_shake_tween.kill()
		
	set_shake_offset(0.0)
	
	var distance := hit_shake_distance
	
	_hit_shake_tween = create_tween()
	
	_hit_shake_tween.tween_method(set_shake_offset, 0.0, -distance, 0.04)
	_hit_shake_tween.tween_method(set_shake_offset, -distance, distance, 0.06)
	_hit_shake_tween.tween_method(set_shake_offset, distance, -distance * 0.5, 0.05)
	_hit_shake_tween.tween_method(set_shake_offset, -distance * 0.05, 0.0, 0.05)

func spawn_destruction_effect() -> void:
	if data == null:
		return
		
	if data.destruction_effect == null:
		return
		
	var effect := data.destruction_effect.instantiate() as Node2D
	
	if effect == null:
		push_warning("Efeito de destruição precisa herdar Node2D")
		return
	
	var effect_position : Vector2 = (
		get_target_world_position() + data.destruction_effect_offset
	)
	
	get_tree().current_scene.add_child(effect)
	effect.global_position = effect_position
	effect.scale = data.destruction_effect_scale
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
