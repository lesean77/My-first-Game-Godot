class_name HairData
extends Resource

enum HorizontalMode {
	MIRRORED_SIDE,
	SEPARATE_LEFT_RIGHT
}

@export var id: int
@export var display_name: String

@export var hair_frames: SpriteFrames

@export var icon: Texture2D

@export_category("Direction")
@export var horizontal_mode: HorizontalMode = HorizontalMode.MIRRORED_SIDE

@export_category("Accessory")
@export var has_accessory: bool = false

func get_horizontal_animation(
	base_animation: StringName,
	facing_left: bool
) -> StringName:
	
	if horizontal_mode == HorizontalMode.SEPARATE_LEFT_RIGHT:
		if facing_left:
			return StringName("%s_left" % base_animation)
	
	return StringName("%s_side" % base_animation)
