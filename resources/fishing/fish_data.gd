class_name FishData
extends Resource

@export_category("Fight")

@export var speed: float = 45.0
@export var acceleration: float = 140.0
@export var randomness: float = 0.65

@export var direction_change_min: float = 0.35
@export var direction_change_max: float = 1.10

@export var pause_chance: float = 0.10
@export var burst_chance: float = 0.08
@export var burst_multiplier: float = 1.55

@export_category("Start")

@export var spawn_max_distance: float = 35.0
@export var initial_progress_min: float = 0.20
@export var initial_progress_max: float = 0.30
