extends CharacterBody2D

enum Facing {
	DOWN,
	UP,
	SIDE
}

@export_category("Stats")
@export var walk_speed : float = 70.0
@export var run_speed : float = 120.0

@export var low_health_percent : float = 0.30
@export var max_health : int = 100
@export var current_health : int = 100

var facing : Facing = Facing.DOWN
var facing_left : bool = false
var is_attacking : bool = false

@onready var player_input = $PlayerInput
@onready var player_movement = $PlayerMovement
@onready var player_animation = $PlayerAnimation
@onready var player_controller = $PlayerController
@onready var player_interaction = $PlayerInteraction
@onready var player_action = $PlayerAction
@onready var player_attack = $PlayerAttack
@onready var player_equipment = $PlayerEquipment
@onready var player_farming = $PlayerFarming
@onready var player_fishing = $PlayerFishing
@onready var player_tools_utils = $PlayerToolUtils
@onready var fishing_ui = $FishingUI

func _ready() -> void:
	player_controller.setup(
		self,
		player_input,
		player_movement,
		player_animation,
		player_interaction,
		player_action,
		player_attack,
		player_equipment,
		player_farming,
		player_fishing,
		player_tools_utils,
		fishing_ui
	)
	
func _physics_process(delta: float) -> void:
	player_controller.physics_update(delta)

func is_low_health() -> bool:
	return current_health <= max_health * low_health_percent
