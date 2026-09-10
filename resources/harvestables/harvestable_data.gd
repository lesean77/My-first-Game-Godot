class_name HarvestableData
extends Resource

@export_category("Identity")
@export var display_name : String = "Exemplo"

@export_category("Durability")
@export var max_health : int = 1
@export var damage_per_action : int = 1

@export_category("Required action")
@export var action_type : ActionType.Type

@export_category("Hit Drops")
@export var hit_drop_item_id : StringName
@export var hit_drop_amount_min : int = 1
@export var hit_drop_amount_max : int = 1
@export var drop_sprite_sheet : Texture2D

@export var drop_sprite_size: Vector2i = Vector2i(16, 16)


@export_range(0.0, 100.0, 0.1) var hit_drop_chance : float = 25.0

@export_category("Destroyed")
@export var drop_item_id : StringName
@export var drop_amount_min : int = 1
@export var drop_amount_max : int = 1

@export_range(0.0, 100.0, 0.1) var drop_chance : float = 100.0

@export_category("Physical Collision")
@export var has_physical_collision : bool = true
@export var physical_collision_offset : Vector2 = Vector2.ZERO

@export_category("Visual")
@export var sprite_offset: Vector2 = Vector2.ZERO

@export_category("Target")
@export var target_offset: Vector2 = Vector2.ZERO

@export_category("Effects")
@export var destruction_effect: PackedScene
@export var destruction_effect_offset: Vector2 = Vector2.ZERO
@export var destruction_effect_scale: Vector2 = Vector2.ONE

func get_random_drop_texture() -> AtlasTexture:
	if drop_sprite_sheet == null:
		return null
	
	var columns: int = 2
	var rows: int = 4
	
	var index: int = randi_range(0, columns * rows - 1)
	
	var column: int = index % columns
	var row: int = floori(float(index) / float(columns))
	
	var atlas := AtlasTexture.new()
	atlas.atlas = drop_sprite_sheet
	atlas.region = Rect2(
		Vector2(
			column * drop_sprite_size.x,
			row * drop_sprite_size.y
		),
		Vector2(drop_sprite_size)
	)
	
	return atlas
