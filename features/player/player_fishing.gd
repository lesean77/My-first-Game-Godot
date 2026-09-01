class_name PlayerFishing
extends Node

# SIGNALS

signal cast_started
signal cast_power_changed(power: float)
signal cast_power_finished(power: float)

signal bobber_released(start_position: Vector2, target_position: Vector2)
signal bobber_landed(position: Vector2)

signal fish_bitten
signal fishing_cancelled

signal fishing_fight_started
signal fight_values_changed(progress: float)

signal fish_caught
signal fish_escaped

signal bite_indicator_shown
signal bite_indicator_hidden

signal capture_return_finished

# STATES
enum FishingState {
	NONE,
	PREPARING,
	CASTING,
	WAITING,
	FISH_ON_HOOK,
	FIGHTING,
	CANCELLING,
	FINISHED,
	CANCELLED
}

# EXPORTED SETTINGS
@export_category("Bobber")
@export var fishing_bobber_scene : PackedScene

@export_category("Cast Power")
@export var minimum_cast_power : float = 0.1

@export var cast_speed: float = 0.8

@export_category("Cast Distance")
@export var min_cast_distance: float = 8.0
@export var max_cast_distance: float = 80.0
@export var distance_per_rod_damage: float = 4.0
@export var absolute_max_cast_distance: float = 240.0

@export_category("Bite simulation")
@export var min_bite_wait_time: float = 2.0
@export var max_bite_wait_time: float = 6.0
@export var hook_window_duration: float = 1.25

@export_category("Fishing Fight")
@export_range(0.0, 1.0) var initial_progress_min: float = 0.20
@export_range(0.0, 1.0) var initial_progress_max: float = 0.32
@export_range(0.0, 1.0) var good_start_chance: float = 0.15
@export_range(0.0, 1.0) var good_start_min: float = 0.35
@export_range(0.0, 1.0) var good_start_max: float = 0.45

@export var progress_gain_speed: float = 0.35
@export var progress_loss_speed: float = 0.15

@export_category("Capture Finish")
# Pequena pausa quando chega a 100%
@export var capture_freeze_duration: float = 0.20
# Tempo do peixe/boia voltando até o player
@export var capture_return_duration: float = 0.55

@export_category("Fishing Fight Start")
# Tempo após iniciar o minigame em que o progresso ainda não pode diminuir
@export var fight_start_grace_duration: float = 0.65

@export_category("Fight - Cast Distance")
# Até essa distância não existe penalidade.
@export var full_gain_distance: float = 20.0

# A partir dessa distância atinge a penalidade máxima.
@export var slow_gain_distance: float = 100.0

# Multiplicador quando o arremesso é muito distante.
# 0.55 = ganha apenas 55% do progresso normal.
@export_range(0.1, 1.0) var far_cast_gain_multiplier: float = 0.55

@export_category("Fight - Gain Ramp")
# Quantos segundos demora para atingir o ganho máximo.
@export var gain_ramp_duration: float = 8.0

# Quanto o ganho pode aumentar durante a luta.
# 1.40 = até 40% a mais
@export var gain_ramp_max_multiplier: float = 1.40
@export_category("Cancel Cast")
@export var cancel_cast_duration: float = 0.4
@export var cancel_return_start_ratio: float = 0.35

# REFERENCES
var player
var player_animation : PlayerAnimation
var player_action

var current_equipment: EquipmentData
var active_bobber : FishingBobber

# RUNTIME STATE
var state : FishingState = FishingState.NONE
var fight_start_grace_remaining: float = 0.0
var fight_distance_gain_multiplier: float = 1.0
var fight_elapsed_time: float = 0.0


# CAST POWER
var cast_power: float = 0.0
var cast_power_direction: float = 1.0

# PENDING CAST
var pending_cast_position: Vector2 = Vector2.ZERO
var pending_mouse_position: Vector2 = Vector2.ZERO
var pending_cast_distance: float = 0.0

var bobber_has_been_released: bool = false

# BITE SIMULATION
var bite_wait_remaining: float = 0.0
var hook_window_remaining: float = 0.0

# FISHING FIGHT
var fight_progress: float = 0.0
var fish_in_catch_bar: bool = false
var result_hold_remaining: float = 0.0
var result_hold_duration: float = 1.0
var bobber_progress_floor: float = 0.0
var fight_won: bool = false
var capture_return_started: bool = false

# CANCEL
var cancel_elapsed: float = 0.0

func setup(
	player_ref,
	animation_ref,
	action_ref
) -> void:
	player = player_ref
	player_animation = animation_ref
	player_action = action_ref

# STATE QUERIES
func is_active() -> bool:
	return state != FishingState.NONE

func is_preparing() -> bool:
	return state == FishingState.PREPARING
	
func is_waiting() -> bool:
	return state == FishingState.WAITING

func is_fighting() -> bool:
	return state == FishingState.FIGHTING

func is_cancelling() -> bool:
	return state == FishingState.CANCELLING
	
# START FISHING
func cast_line(equipment: EquipmentData) -> void:
	if is_active():
		return
		
	if not _can_start_fishing(equipment):
		return
	
	current_equipment = equipment
	
	_reset_cast_data()
	_reset_bite_data()
	_reset_fight_data()
	
	cast_power = minimum_cast_power
	cast_power_direction = 1.0
	
	state = FishingState.PREPARING
	
	player_animation.enter_fishing()
	
	cast_started.emit()
	cast_power_changed.emit(cast_power)
	
	print(
		"Pesca iniciada com: ", current_equipment.display_name
	)
	
func _can_start_fishing(equipment: EquipmentData) -> bool:
	if equipment == null:
		push_error(
			"PlayerFishing: EquipmentData é nulo."
		)
		return false
	
	if player == null:
		push_error(
			"PlayerFishing: referência do player não configurada."
		)
		return false
		
	if player_animation == null:
		push_error(
			"PlayerFishing: PlayerAnimation não configurada."
		)
		return false
	
	return true

# UPDATE
func physics_update(delta: float) -> void:
	match state:
		FishingState.PREPARING:
			_update_cast_power(delta)
		
		FishingState.WAITING:
			_update_waiting(delta)
			
		FishingState.FISH_ON_HOOK:
			_update_fish_on_hook(delta)
			
		FishingState.FIGHTING:
			_update_fighting(delta)
			
		FishingState.FINISHED:
			_update_finished(delta)
		
		FishingState.CANCELLING:
			_update_cancelling(delta)
		
func _update_cast_power(delta: float) -> void:
	cast_power += (
		cast_power_direction * cast_speed * delta
	)
	
	if cast_power >= 1.0:
		cast_power = 1.0
		cast_power_direction = -1.0
		
	elif cast_power <= minimum_cast_power:
		cast_power = minimum_cast_power
		cast_power_direction = 1.0
		
	cast_power_changed.emit(cast_power)

func _update_waiting(delta: float) -> void:
	bite_wait_remaining -= delta
	
	if bite_wait_remaining > 0.0:
		return
	
	trigger_fish_bite()


func _update_fish_on_hook(delta: float) -> void:
	hook_window_remaining -= delta
	
	if hook_window_remaining > 0.0:
		return
		
	fish_escape()

func _update_fighting(delta: float) -> void:
	fight_elapsed_time += delta
	
	# Grace Period
	if fight_start_grace_remaining > 0.0:
		fight_start_grace_remaining -= delta
	
	# Peixe dentro da Catch Bar
	if fish_in_catch_bar:
		var gain_ramp: float = _get_fight_gain_ramp()
		
		var effective_gain_speed: float = (
			progress_gain_speed
			* fight_distance_gain_multiplier
			* gain_ramp
		)
		
		fight_progress += effective_gain_speed * delta
	# Peixe fora da Catch Bar
	elif fight_start_grace_remaining <= 0.0:
		fight_progress -= progress_loss_speed * delta
	
	fight_progress = clampf(fight_progress, 0.0, 1.0)
	
	# Se o peixe ganhou terreno e o progresso caiu
	# abaixo do ponto inicial, esse novo valor passa
	# a ser o ponto mais distante da boia.
	if fight_progress < bobber_progress_floor:
		bobber_progress_floor = fight_progress
	
	var bobber_progress: float = 0.0
	
	if fight_progress > bobber_progress_floor:
		bobber_progress = inverse_lerp(
			bobber_progress_floor,
			1.0,
			fight_progress
		)
	
	bobber_progress = clampf(bobber_progress, 0.0, 1.0)
	
	if is_instance_valid(active_bobber):
		active_bobber.set_fight_progress(bobber_progress)
		
	# UI
	fight_values_changed.emit(fight_progress)
	
	# Resultado
	if fight_progress <= 0.0:
		lose_fishing_fight()
		return
	
	if fight_progress >= 1.0:
		win_fishing_fight()

func _update_finished(delta: float) -> void:
	if result_hold_remaining > 0.0:
		result_hold_remaining -= delta
		return
	
	# Vitória:
	# começa o retorno do peixe para o player.
	if fight_won:
		if not capture_return_started:
			_start_capture_return()
			
		return
		
	# Derrota:
	# mantém o comportamento atual.
	if Input.is_action_pressed("attack"):
		return
	
	_cleanup_fishing()
	
func _update_cancelling(delta: float) -> void:
	cancel_elapsed += delta
	
	var safety_duration : float = (
		cancel_cast_duration + 0.20
	)
	
	if cancel_elapsed < safety_duration:
		return
	
	push_warning(
			"PlayerFishing: CancelCast finalizado pelo temporizador de segurança"
		)
		
	_finish_cancel()
	
# CAST PREPARATION
func confirm_cast() -> void:
	if state != FishingState.PREPARING:
		return
	
	var effective_power: float = clampf(cast_power, minimum_cast_power, 1.0)
	
	var rod_max_distance: float = get_current_rod_max_distance()
	
	pending_cast_distance = lerpf(
		min_cast_distance,
		rod_max_distance,
		effective_power
	)
	
	pending_cast_distance = clampf(
		pending_cast_distance, 
		min_cast_distance,
		rod_max_distance
	)
	
	pending_mouse_position = player.get_global_mouse_position()
	
	var start_position: Vector2 = get_rod_tip_position()
	var cast_direction: Vector2 = _get_cast_direction(start_position)
	
	pending_cast_position = (
		start_position
		+ cast_direction * pending_cast_distance
	)
	
	cast_power_finished.emit(effective_power)
	
	state = FishingState.CASTING
	bobber_has_been_released = false
	
	player_animation.set_fishing_state(&"Cast")
	
	print(
		"Arremesso preparado",
		" | Power: ", effective_power,
		" | Mouse salvo: ", pending_mouse_position,
		" | Alcance máximo: ", rod_max_distance,
		" | Distância escolhida: ", pending_cast_distance
	)

# ANIMATION CALL METHODS
func launch_bobber() -> void:
	if state != FishingState.CASTING:
		return
		
	if bobber_has_been_released:
		return
	
	bobber_has_been_released = true
	
	var start_position: Vector2 = get_rod_tip_position()
	
	bobber_released.emit(start_position, pending_cast_position)
	
	_spawn_and_throw_bobber(start_position, pending_cast_position)
	
func finish_cast_animation() -> void:
	if state != FishingState.CASTING:
		return
			
	if not bobber_has_been_released:
		return
	
	player_animation.set_fishing_state(&"Waiting")

# CAST CALCULATIONS
func _get_cast_direction(start_position: Vector2) -> Vector2:
	var to_mouse: Vector2 = (pending_mouse_position - start_position)
	
	if to_mouse.length_squared() <= 0.001:
		return get_facing_direction()
		
	return to_mouse.normalized()
	
func get_facing_direction() -> Vector2:
	if player == null:
		return Vector2.DOWN
	
	match player.facing:
		player.Facing.DOWN:
			return Vector2.DOWN
		player.Facing.UP:
			return Vector2.UP
		player.Facing.SIDE:
			if player.facing_left:
				return Vector2.LEFT
				
			return Vector2.RIGHT
			
	return Vector2.DOWN
	
func get_rod_tip_position() -> Vector2:
	if player == null:
		return Vector2.ZERO
		
	var rod_tip := ( player.get_node_or_null("RodTip")) as Node2D
	
	if rod_tip == null:
		return player.global_position
	
	var local_tip_position: Vector2 = (rod_tip.position)
	
	if (player.facing == player.Facing.SIDE and player.facing_left):
		local_tip_position.x = -local_tip_position.x
		
	return player.to_global(local_tip_position)
	
func get_current_rod_max_distance() -> float:
	var rod_damage: float = 0.0
	
	if current_equipment != null:
		rod_damage = float(current_equipment.damage)
	
	var maximum_distance: float = (
		max_cast_distance 
		+ rod_damage * distance_per_rod_damage
	)
	
	return clampf(
		maximum_distance,
		min_cast_distance,
		absolute_max_cast_distance
	)

func get_cancel_return_duration() -> float:
	var remaining_ratio: float = 1.0 - cancel_return_start_ratio
	
	return maxf(
		cancel_cast_duration * remaining_ratio,
		0.01
	)

func _calculate_distance_gain_multiplier() -> float:
	if slow_gain_distance <= full_gain_distance:
		return 1.0
	
	var distance_ratio: float = inverse_lerp(
		full_gain_distance,
		slow_gain_distance,
		pending_cast_distance
	)
	
	distance_ratio = clampf(distance_ratio, 0.0, 1.0)
	
	return lerpf(1.0, far_cast_gain_multiplier, distance_ratio)
	
func _get_fight_gain_ramp() -> float:
	if gain_ramp_duration <= 0.0:
		return gain_ramp_max_multiplier
	
	var ratio: float = clampf(
		fight_elapsed_time / gain_ramp_duration,
		0.0,
		1.0
	) 
	
	return lerpf(1.0, gain_ramp_max_multiplier, ratio)
	
# BOBBER
func _spawn_and_throw_bobber(
	start_position: Vector2,
	target_position: Vector2
) -> void:
	if fishing_bobber_scene == null:
		push_error(
			"PlayerFishing: FishingBobberScene não configurada."
		)
			
		_on_bobber_landed(target_position)
		return
		
	_remove_active_bobber()
		
	active_bobber = (
		fishing_bobber_scene.instantiate() as FishingBobber
	)
		
	if active_bobber == null:
		push_error(
			"PlayerFishing: a cena instancia não é FishingBobber."
		)
		return
		
	get_tree().current_scene.add_child(active_bobber)
		
	active_bobber.setup(
		Callable(self, "get_rod_tip_position"),
		Callable(self, "_is_fishable_position")
	)
		
	active_bobber.landed.connect(_on_bobber_landed, CONNECT_ONE_SHOT)
	active_bobber.return_finished.connect(_on_capture_return_finished)
		
	active_bobber.throw_to(start_position, target_position)
		
func _on_bobber_landed(position: Vector2) -> void:
	if state != FishingState.CASTING:
		return
	
	if not _is_fishable_position(pending_cast_position):
		print("Não é possível pescar nessa posição")
		
		_finish_cancel()
		return
		
	state = FishingState.WAITING
		
	bobber_landed.emit(position)
	
	bite_wait_remaining = randf_range(
		min_bite_wait_time,
		max_bite_wait_time
	)
		
	print(
		"Boia pousou em: ", position,
		" | Mordida em: ", bite_wait_remaining,
		" segundos."
	)

func _remove_active_bobber() -> void:
	if not is_instance_valid(active_bobber):
		active_bobber = null
		return
	
	active_bobber.remove_bobber()
	active_bobber = null
# BITE
func trigger_fish_bite() -> void:
	if state != FishingState.WAITING:
		return
	
	state = FishingState.FISH_ON_HOOK
	hook_window_remaining = hook_window_duration
	
	if is_instance_valid(active_bobber):
		active_bobber.play_bite_visual()
		active_bobber.play_water_ripple(2.0)
	
	fish_bitten.emit()
	bite_indicator_shown.emit()
	
	print(
		"PUXOU! Você tem ", hook_window_duration,
		" segundos para fisgar."
	)
	
func hook_fish() -> void:
	if state  != FishingState.FISH_ON_HOOK:
		return
		
	bite_indicator_hidden.emit()
	
	hook_window_remaining = 0.0
	
	_start_fight_data()
	
	state = FishingState.FIGHTING
	
	if is_instance_valid(active_bobber):
		active_bobber.set_line_fighting()
	
	player_animation.set_fishing_state(&"Fighting")
	
	fishing_fight_started.emit()
	
	print("Minigame iniciado!")

func _start_fight_data() -> void:
	fight_progress = _get_initial_fight_progress()
	
	# A boia começa sempre no local onde caiu, independente do progresso inicial.
	bobber_progress_floor = fight_progress
	
	fish_in_catch_bar = false
	
	fight_start_grace_remaining = fight_start_grace_duration
	
	fight_elapsed_time = 0.0
	
	fight_distance_gain_multiplier = _calculate_distance_gain_multiplier()
	

func _get_initial_fight_progress() -> float:
	if randf() < good_start_chance:
		return randf_range(
			good_start_min,
			good_start_max
		)
		
	return randf_range(
		initial_progress_min,
		initial_progress_max
	)
	
func fish_escape() -> void:
	if state != FishingState.FISH_ON_HOOK:
		return
	
	bite_indicator_hidden.emit()
	fish_escaped.emit()
	
	state = FishingState.WAITING
	
	if is_instance_valid(active_bobber):
		active_bobber.set_line_waiting()
		active_bobber.play_waiting_visual()
		
	hook_window_remaining = 0.0
	
	bite_wait_remaining = randf_range(
		min_bite_wait_time,
		max_bite_wait_time
	)
	
	player_animation.set_fishing_state(&"Waiting")
	
	print("Você perdeu a fisgada")
	
# FISHING FIGHT
func set_fish_in_catch_bar(value: bool) -> void:
	fish_in_catch_bar = value
	
func win_fishing_fight() -> void:
	if state != FishingState.FIGHTING:
		return
		
	state = FishingState.FINISHED
	
	fight_won = true
	capture_return_started = false
	
	result_hold_remaining = capture_freeze_duration
	
	if is_instance_valid(active_bobber):
		active_bobber.freeze_fight_position()
		
	print("Exemplar capturado!")
	
	fish_caught.emit()
	
func lose_fishing_fight() -> void:
	if state != FishingState.FIGHTING:
		return
		
	state = FishingState.FINISHED
	
	result_hold_remaining = result_hold_duration
	
	print("Escapou!!!")
	
	fish_escaped.emit()
	
# CANCELLATION
func cancel_fishing() -> void:
	if not is_active():
		return
	
	if state == FishingState.CANCELLING:
		return
		
	match state:
		FishingState.CASTING, FishingState.WAITING:
			_start_cancel_cast()
		
		FishingState.PREPARING, \
		FishingState.FISH_ON_HOOK, \
		FishingState.FIGHTING:
			_finish_cancel()
		
		_:
			_finish_cancel()
			
func _start_capture_return() -> void:
	if capture_return_started:
		return
		
	capture_return_started = true
	
	if not is_instance_valid(active_bobber):
		_finish_capture_return()
		return
	
	active_bobber.show_caught_fish()
	
	active_bobber.start_returning(
		Callable(self, "get_rod_tip_position"),
		capture_return_duration
	)
	
func _start_cancel_cast() -> void:
	if not is_instance_valid(active_bobber):
		_finish_cancel()
		return
		
	state = FishingState.CANCELLING
	cancel_elapsed = 0.0
	
	bite_indicator_hidden.emit()
	
	player_animation.set_fishing_state(&"CancelCast")
	
func _finish_cancel() -> void:
	if not is_active():
		return
		
	state = FishingState.CANCELLED
	
	bite_indicator_hidden.emit()
	fishing_cancelled.emit()
	
	_cleanup_fishing()

func launch_cancel_return() -> void:
	if state != FishingState.CANCELLING:
		return
		
	if not is_instance_valid(active_bobber):
		return
		
	active_bobber.start_returning(
		Callable(self, "get_player_position"),
		get_cancel_return_duration()
	)
	
# RESET / CLEANUP
func _cleanup_fishing() -> void:
	_remove_active_bobber()
	
	current_equipment = null
	
	_reset_cast_data()
	_reset_bite_data()
	_reset_fight_data()
	
	cancel_elapsed = 0.0
	
	bite_indicator_hidden.emit()
	
	player_animation.exit_fishing(&"Idle")
	
	state = FishingState.NONE
	
	if (player_action != null and player_action.is_busy()):
		player_action.finish_action()
	
func _reset_cast_data() -> void:
	cast_power = 0.0
	cast_power_direction = 1.0
	
	pending_mouse_position = Vector2.ZERO
	pending_cast_position = Vector2.ZERO
	pending_cast_distance = 0.0
	
	bobber_has_been_released = false
	
func _reset_bite_data() -> void:
	bite_wait_remaining = 0.0
	hook_window_remaining = 0.0
	
func _reset_fight_data() -> void:
	fight_progress = 0.0
	fish_in_catch_bar = false
	
	fight_start_grace_remaining = 0.0
	fight_elapsed_time = 0.0
	fight_distance_gain_multiplier = 0.0
	
	bobber_progress_floor = 0.0
	
	result_hold_remaining = 0.0
	
	fight_won = false
	capture_return_started = false
	
func get_player_position() -> Vector2:
	if player == null:
		return Vector2.ZERO
		
	return player.global_position
	
func _get_world_map() -> WorldTileMap:
	return get_tree().get_first_node_in_group("world_map") as WorldTileMap
	
func _is_fishable_position(world_position: Vector2) -> bool:
	var world_map := _get_world_map()
	
	if world_map == null:
		push_warning("PlayerFishing: WorldTileMap não encontrado.")
		return false
		
	return world_map.is_fishable(world_position)
	
func _on_capture_return_finished() -> void:
	if state != FishingState.FINISHED:
		return
		
	if not fight_won:
		return
	
	_finish_capture_return()

func _finish_capture_return() -> void:
	capture_return_finished.emit()
	_cleanup_fishing()
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
