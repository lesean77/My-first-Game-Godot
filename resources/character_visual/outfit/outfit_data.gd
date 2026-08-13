class_name OutfitData
extends Resource

@export var id: int
@export var display_name: String
 
@export_category("Male")
@export var male_frames: SpriteFrames
@export var male_icon: Texture2D

@export_category("Female")
@export var female_frames: SpriteFrames
@export var female_icon: Texture2D

func get_frames_for_body(body_type: int) -> SpriteFrames:
	match body_type:
		1:
			return male_frames
		2:
			return female_frames
		_:
			return male_frames


func get_icon_for_body(body_type: int) -> Texture2D:
	match body_type:
		1:
			return male_icon
		2:
			return female_icon
		_:
			return male_icon
