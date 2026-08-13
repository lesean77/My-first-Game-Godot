class_name Harvestable 
extends StaticBody2D

@export var data : HarvestableData

@onready var sprite : Sprite2D = $Sprite2D
@onready var physical_collision : CollisionShape2D = $CollisionShape2D
@onready var hit_area : HitArea = $HitArea

var current_health : int

func _ready() -> void:
	if data == null:
		push_error("Varvestable sem HarvestableData: " + name)
		return
	
	current_health = data.max_health
	sprite.texture = data.texture
	
	configure_physical_collision()
	
	hit_area.configure(
		data.interaction_size,
		data.interaction_offset
	)

func get_action_type() -> ActionType.Type:
	if data == null:
		return ActionType.Type.NONE
	
	return data.action_type

func receive_equipment_hit(_player: Node, equipment: EquipmentData) -> void:
	if equipment == null:
		push_warning("Harvestable recebeu equipamento nulo.")
		return
	
	if data == null:
		push_warning("Harvestable sem HarvestableData.")
		return
	
	if current_health <= 0:
		return
		
	if equipment.action_type != data.action_type:
		print(
			"Ferramenta incorreta em ",
			data.display_name,
			". Recebido: ",
			ActionType.Type.keys()[equipment.action_type],
			" | Necessário: ",
			ActionType.Type.keys()[data.action_type]
		)
		return
	
	var damage: int = maxi(equipment.damage, 1)
	
	current_health -= maxi(current_health - damage, 0)
	
	print(
		data.display_name, 
		" recebeu ",
		damage,
		" de dano. Vida: ",
		"/",
		data.max_health
	)
	
	if current_health <= 0:
		destroy_resource()
		
	try_drop_hit_fragments()

func destroy_resource() -> void:
	var amount := randi_range(
		data.drop_amount_min,
		data.drop_amount_max
	)
	
	if amount > 0 and not data.drop_item_id.is_empty():
		spawn_drop(
			data.drop_item_id,
			amount
		)
	
	print(data.display_name, " foi destruído.")
		
	queue_free()
	
func configure_physical_collision() -> void:
	physical_collision.disabled = not data.has_physical_collision
	
	if not data.has_physical_collision:
		return
		
	var rectangle := physical_collision.shape as RectangleShape2D
	
	if rectangle == null:
		push_error("A colisão fisica precisa ser RectangleShape2D.")
		return
		
	var unique_rectangle := rectangle.duplicate() as RectangleShape2D
	physical_collision.shape = unique_rectangle

	unique_rectangle.size = data.physical_collision_size
	physical_collision.position = data.physical_collision_offset
	

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
	
	spawn_drop(
		data.hit_drop_item_id,
		amount
	)

func spawn_drop(item_id: StringName, amount: int) -> void:
	print("Drop gerado: ", amount, "x ", item_id)
