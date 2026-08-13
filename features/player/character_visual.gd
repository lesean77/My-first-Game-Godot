extends Node2D

enum Facing {
	SOUTH, 
	EAST,
	NORTH,
	WEST
}

@onready var body: AnimatedSprite2D = $Body
@onready var eyes: AnimatedSprite2D = $Eyes
@onready var hair: AnimatedSprite2D = $Hair
@onready var outfit: AnimatedSprite2D = $Outfit
@onready var animation_player: AnimationPlayer = $PreviewAnimationPlayer

var facing : Facing = Facing.SOUTH

func start_idle() -> void:
	facing = Facing.SOUTH
	update_idle_animation()
	
func turn_right() -> void:
	match facing:
		Facing.SOUTH:
			facing = Facing.EAST
			
		Facing.EAST:
			facing = Facing.NORTH
		
		Facing.NORTH:
			facing = Facing.WEST
		
		Facing.WEST:
			facing = Facing.SOUTH
		
	update_idle_animation()
	
func turn_left() -> void:
	match facing:
		Facing.SOUTH:
			facing = Facing.WEST
			
		Facing.WEST:
			facing = Facing.NORTH
		
		Facing.NORTH:
			facing = Facing.EAST
		
		Facing.EAST:
			facing = Facing.SOUTH
	
	update_idle_animation()
	
func update_idle_animation() -> void:
	match facing:
		Facing.SOUTH:
			set_flip(false)
			animation_player.play("idle_down")
			
		Facing.EAST:
			set_flip(false)
			animation_player.play("idle_side")
			
		Facing.NORTH:
			set_flip(false)
			animation_player.play("idle_up")
			
		Facing.WEST:
			set_flip(true)
			animation_player.play("idle_side")
			
func set_flip(value: bool) -> void:
	body.flip_h = value
	eyes.flip_h = value
	hair.flip_h = value
	outfit.flip_h = value

func set_body_type(body_data: BodyData) -> void:
	if body_data == null: 
		return
		
	body.sprite_frames = body_data.body_frames
	eyes.sprite_frames = body_data.eyes_frames
	
	refresh_animation()

func set_eye_color(color: Color) -> void:
	var eye_material := eyes.material as ShaderMaterial
	
	if eye_material == null:
		push_warning("Eyes não possui ShaderMaterial.")
		return
	
	eye_material.set_shader_parameter("target_color", color)

func set_hair(hair_data: HairData) -> void:
	if hair_data == null: 
		return
		
	if hair_data.hair_frames == null:
		push_warning(
			"HairData '%s' não possui hair_frames."
			% hair_data.display_name
		)
		return
		
	hair.sprite_frames = hair_data.hair_frames
	refresh_animation()
	
func set_outfit(outfit_data: OutfitData, body_type: int) -> void:
	if outfit_data == null: 
		return
	
	var frames := outfit_data.get_frames_for_body(body_type)
	
	if frames == null:
		push_warning(
			"Outfit '%s' não possui frames para Body Type %s." 
			% [outfit_data.display_name, body_type]
		)
		return
	
	outfit.sprite_frames = frames
	
	refresh_animation()
	
func set_skin_color(_color: Color) -> void:
	pass

func set_hair_color(color: Color) -> void:
	var hair_material := hair.material as ShaderMaterial
	
	if hair_material == null:
		push_warning("Hair não possui ShaderMaterial.")
		return
	
	hair_material.set_shader_parameter(
		"hair_color",
		color
	)

func set_hair_accessory_color(color: Color) -> void:
	var hair_material := hair.material as ShaderMaterial
	
	if hair_material == null:
		push_warning("Hair não possui ShaderMaterial.")
		return
	
	hair_material.set_shader_parameter(
		"accessory_color",
		color
	)
	
func refresh_animation() -> void:
	if animation_player.current_animation.is_empty():
		return
		
	var current_position := animation_player.current_animation_position
	animation_player.seek(current_position, true)
	
