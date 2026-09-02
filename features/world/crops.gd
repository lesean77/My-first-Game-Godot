class_name Crop
extends Node2D

enum Stage {
	SEED,
	SPROUT,
	GROWTH_2,
	GROWTH_3,
	READY,
	ROTTEN
}

var crop_data: CropData
var cell: Vector2i

var stage: Stage = Stage.SEED
var watered_days_in_stage: int = 0
var days_ready: int = 0

@onready var sprite: Sprite2D = $Sprite2D

func setup(definition: CropData, target_cell: Vector2i) -> void:
	crop_data = definition
	cell = target_cell
	
func _ready() -> void:
	refresh_visual()

func process_day(was_watered: bool) -> void:
	if stage == Stage.ROTTEN:
		return
		
	# Maduro envelhece mesmo sem água
	if stage == Stage.READY:
		days_ready += 1
		
		if days_ready >= crop_data.days_before_rot:
			stage = Stage.ROTTEN
			refresh_visual()
		return
		
	if not was_watered:
		return
		
	watered_days_in_stage += 1
	
	if watered_days_in_stage < crop_data.growth_days[int(stage)]:
		return
		
	watered_days_in_stage = 0
	stage = (int(stage) + 1) as Stage
	
	if stage == Stage.READY:
		days_ready = 0
		
	refresh_visual()
	
func is_ready_to_harvest() -> bool:
	return stage == Stage.READY
	
func is_rotten() -> bool:
	return stage == Stage.ROTTEN
	
func refresh_visual() -> void:
	if crop_data == null:
		return
		
	sprite.offset = crop_data.sprite_offset
	sprite.modulate = Color.WHITE
	
	if stage == Stage.ROTTEN:
		if crop_data.rotten_texture != null:
			sprite.texture = crop_data.rotten_texture
		else:
			# Visual provisório enquanto não houver sprite podre.
			sprite.texture = crop_data.textures[int(Stage.READY)]
			sprite.modulate = Color(0.45, 0.30, 0.20)
		return
	
	sprite.texture = crop_data.textures[int(stage)]
	
# Compativel com PlayerAction.apply_collecting_effect().
func collect(player) -> void:
	player.player_farming.collect_crop(self)
	
	
	
	
	
	
	
	
	
	
	
