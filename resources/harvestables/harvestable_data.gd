class_name HarvestableData
extends Resource

@export_category("Identity")
@export var display_name : String = "Exemplo"
@export var texture : Texture2D

@export_category("Durability")
@export var max_health : int = 1
@export var damage_per_action : int = 1

@export_category("Required action")
@export var action_type : ActionType.Type

@export_category("Hit Drops")
@export var hit_drop_item_id : StringName
@export var hit_drop_amount_min : int = 1
@export var hit_drop_amount_max : int = 1

@export_range(0.0, 100.0, 0.1) var hit_drop_chance : float = 25.0

@export_category("Destroyed")
@export var drop_item_id : StringName
@export var drop_amount_min : int = 1
@export var drop_amount_max : int = 1

@export_range(0.0, 100.0, 0.1) var drop_chance : float = 100.0


@export_category("Area Hit")
@export var interaction_size : Vector2 = Vector2(16, 16)
@export var interaction_offset: Vector2 = Vector2(0, -4)

@export_category("Physical Collision")
@export var has_physical_collision : bool = true
@export var physical_collision_size : Vector2 = Vector2(12, 8)
@export var physical_collision_offset : Vector2 = Vector2.ZERO
