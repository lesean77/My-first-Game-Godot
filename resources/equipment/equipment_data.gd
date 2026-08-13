class_name EquipmentData
extends Resource

enum EquipmentType {
	SWORD,
	AXE,
	PICKAXE,
	HOE,
	WATERING_CAN,
	FISHING_ROD,
	SPEAR,
	STAFF,
	DAGGER, 
	BOW,
	BOOK,
	DUAL
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC, 
	LEGENDARY, 
	GODLIKE
}

@export_category("Identity")

@export var id : StringName
@export var display_name : StringName = "Equipment"
@export_multiline var description : String

@export var icon : Texture2D
@export var world_texture : Texture2D

@export_category("Equipment")

@export var equipment_type : EquipmentType = EquipmentType.SWORD
@export var rarity : Rarity = Rarity.COMMON

@export_category("Gameplay")

@export var action_type : ActionType.Type = ActionType.Type.NONE

@export_range(0, 999, 1) var damage : int = 1
@export_range(0.1, 10.0, 0.1) var attack_speed : float = 1.0
@export_range(0, 999, 1) var decay : int = 1

@export_category("Durability")

@export var has_durability : bool = false
@export_range(1, 9999, 1) var max_durability : int = 100
@export_range(0, 1000, 1) var durability_cost : int = 1

@export_category("Hit Area")

@export var hit_area_size : Vector2 = Vector2(16, 16)
@export_range(0.0, 100.0, 1.0) var hit_distance : float = 12.0

@export_category("Animation")

@export var animation_name : StringName

@export_category("Audio")

@export var swing_sound : AudioStream

@export_category("Effect")

@export var hit_particles : PackedScene
