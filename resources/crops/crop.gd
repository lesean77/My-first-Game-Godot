class_name CropData
extends Resource

@export_category("Identity")
@export var id: StringName
@export var display_name: String

@export_category("Growth")
# Duração de cada transição, em dias regados:
# semente -> broto -> crescimento 2 -> crescimento 3 -> maduro.
@export var growth_days: Array[int] = [1, 1, 1, 1]

# Cinco texturas, na mesma ordem dos estados acima.
@export var textures: Array[Texture2D] = []

@export_category("Harvest")
@export var icon_crop: Texture2D
@export var harvest_item_id: StringName
@export var harvest_amount_min: int = 1
@export var harvest_amount_max: int = 2

@export_category("Rot")
@export_range(1, 365, 1) var days_before_rot: int = 3
@export var rotten_texture: Texture2D

@export_category("Visual")
@export var sprite_offset: Vector2 = Vector2.ZERO


func is_valid_definition() -> bool:
	if id == &"" or harvest_item_id == &"":
		return false
		
	if growth_days.size() != 4 or textures.size() != 5:
		return false
	
	# O broto nasce após o primeiro dia regado. 
	if growth_days[0] != 1:
		return false
	
	for duration in growth_days:
		if duration < 1:
			return false
	
	for texture in textures:
		if texture == null:
			return false
			
	return harvest_amount_min > 0 and days_before_rot > 0
	
