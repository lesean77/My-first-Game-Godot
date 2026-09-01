class_name FishingBobber
extends Node2D

signal landed(position: Vector2)
signal removed
signal return_finished

@export_category("Throw")
@export var throw_duration: float = 0.35
@export var arc_height: float = 18.0

@export_category("Return")
@export var default_return_duration: float = 0.40

@export var return_arc_height: float = 28.0
@export var return_target_height: float = 0.0

@export_category("Fight")
# Distancia mínima que a boia pode chegar da ponta da vara
@export var fight_near_player_distance: float = 12.0
# Suavização visual do movimento
@export var fight_position_response: float = 6.0

@export_category("Fishing Line")
@export var line_end_offset: Vector2 =  Vector2.ZERO

@onready var bobber_visual: Node2D = $BobberVisual
@onready var bobber_sprite: Sprite2D = $BobberVisual/BobberSprite
@onready var water_ripple: AnimatedSprite2D = $WaterRipple
@onready var fishing_line: FishingLine = $FishingLine
@onready var detection_area: Area2D = $DetectionArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var fight_splash: GPUParticles2D = $FightSplash
@onready var caught_fish_visual: Node2D = get_node_or_null("CaughtFishVisual") as Node2D

@export_category("Bobber Bite")
# Quanto a boia afunda quando o peixe puxa.
@export var bite_visual_offset_y: float = 2.0

@export_category("Bobber Water Sync")
@export var bobber_idle_animation: StringName = &"bobber_idle"

# Deve ser igual á duração REAL do ciclo de água.
@export var water_animation_duration: float = 2.0
#Permite corrigir manualmente a fase caso necessário.
@export var water_animation_phase_offset: float = 0.0


@export_category("Fight - Movement")
# Distancia usada para perceber que existe uma borda próxima. 
@export var edge_detection_distance: float = 8.0

# Velocidade da movimentação lateral do peixe na borda.
@export var edge_move_speed: float = 14.0

# Limites Verticais.
@export var edge_limit_up: float = 24.0
@export var edge_limit_down: float = 24.0
# Limites Horizontais.
@export var edge_limit_left: float = 24.0
@export var edge_limit_right: float = 24.0

# RUNTIME
var rod_tip_position_provider: Callable
var return_target_provider: Callable

var start_position: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO

var throw_elapsed: float = 0.0
var is_throwing: bool = false

var return_start_position: Vector2 = Vector2.ZERO
var return_duration: float = 0.40
var return_elapsed: float = 0.0
var is_returning: bool = false

var is_landed: bool = false

var fight_origin_position: Vector2 = Vector2.ZERO
var fight_progress_target: float = 0.0
var is_fight_positioning: bool = false

var fight_base_position: Vector2 = Vector2.ZERO

# Progresso Visual real da boia entre: 
# 0.0 = ponto onde a luta começou
# 1.0 = próximo da vara
var fight_visual_progress: float = 0.0

# Usado para descobrir quanto o progresso aumentou ou diminuiu desde a última atualização.
var fight_previous_progress_target: float = 0.0

# FISHABLE
var fishable_position_provider: Callable

# EDGE LIMIT
var edge_active: bool = false

# Vector2.DOWN significa movimento vertical.
# Vector2.RIGHT significa movimento horizontal.
var edge_axis: Vector2 = Vector2.ZERO

# -1 = cima/esquerda
# 1 = baixo/direita
var edge_direction: float = 1.0

# Distancia atual em relação à posição-base.
var edge_offset: float = 0.0

func _ready() -> void:
	visible = false
	
	stop_water_ripple()
	
	fight_splash.emitting = false
	
	if not water_ripple.animation_finished.is_connected(_on_water_ripple_finished):
		water_ripple.animation_finished.connect(_on_water_ripple_finished)

func setup(position_provider: Callable, fishable_provider: Callable) -> void:
	rod_tip_position_provider = position_provider
	fishable_position_provider = fishable_provider

	fishing_line.setup(
		rod_tip_position_provider,
		Callable(self, "get_line_end_position")
	)

func _process(delta: float) -> void:
	if is_throwing:
		_update_throw(delta)
		return

	if is_returning:
		_update_returning(delta)
	
	if is_fight_positioning:
		_update_fight_position(delta)

# BOBBER VISUAL
func play_waiting_visual() -> void:
	bobber_visual.position.y = 0.0
	
	_sync_bobber_idle_to_water()

func play_bite_visual() -> void:
	# Continua usando o mesmo movimento da boia, mas ela fica mais afundada.
	bobber_visual.position.y = bite_visual_offset_y
	
	# Se a animação de água deve exister SOMENTE no WAITING, escondemos aqui. 
	#animation.visible = false
	
	_sync_bobber_idle_to_water()

func stop_bobber_visual() -> void: 
	animation_player.stop()
	
	bobber_visual.position.y = 0.0

func play_water_ripple(speed_multiplier: float = 1.0) -> void:
	if water_ripple == null:
		return
		
	water_ripple.visible = true
	water_ripple.frame = 0
	
	water_ripple.play(&"ondulation", speed_multiplier)

func stop_water_ripple() -> void:
	if water_ripple == null:
		return
		
	water_ripple.stop()
	water_ripple.frame = 0
	water_ripple.visible = false
			
# THROW
func throw_to(
	from_position: Vector2,
	to_position: Vector2
) -> void:
	start_position = from_position
	target_position = to_position

	global_position = start_position
	visible = true

	throw_elapsed = 0.0

	is_throwing = true
	is_returning = false
	is_landed = false

	_set_detection_enabled(false)

	fishing_line.set_mode(
		FishingLine.LineMode.CASTING
	)


func _update_throw(delta: float) -> void:
	if throw_duration <= 0.0:
		global_position = target_position
		_finish_throw()
		return

	throw_elapsed += delta

	var progress: float = clampf(
		throw_elapsed / throw_duration,
		0.0,
		1.0
	)

	var base_position: Vector2 = start_position.lerp(
		target_position,
		progress
	)

	var arc_offset: float = (
		sin(progress * PI)
		* arc_height
	)

	global_position = (
		base_position
		+ Vector2.UP * arc_offset
	)

	fishing_line.set_cast_progress(progress)

	if progress >= 1.0:
		_finish_throw()

func _update_fight_position(delta: float) -> void:
	if not rod_tip_position_provider.is_valid():
		return
		
	var rod_position: Vector2 = rod_tip_position_provider.call()
	var original_direction: Vector2 = fight_origin_position - rod_position
	var original_distance: float = original_direction.length()
	
	if original_distance <= 0.001:
		return
	
	var direction_from_rod: Vector2 = original_direction.normalized()
	var direction_to_rod: Vector2 = -direction_from_rod
	
	# Posição mais proxima que a boia poderia chegar da ponta da vara.
	var near_position: Vector2 = rod_position + direction_from_rod * fight_near_player_distance
	
	var travel_distance: float = fight_origin_position.distance_to(near_position)
	
	if travel_distance <= 0.001:
		return
	
	# Variação do Progresso
	var progress_delta: float = fight_progress_target - fight_previous_progress_target
	
	fight_previous_progress_target = fight_progress_target
	
	# Em vez de usar diretamente o progresso recebido, aplicar somente VARIAÇÃO,
	# sobre a posição visual atual da boia.
	var desired_visual_progress: float = clampf(
		fight_visual_progress + progress_delta,0.0, 1.0
	)
	
	var desired_base_position: Vector2 = (
		fight_origin_position.lerp(near_position, desired_visual_progress)
	)
	
	# FISHABLE
	if _is_fishable(desired_base_position):
		fight_base_position = desired_base_position
		
		fight_visual_progress = desired_visual_progress
	
	else:
		# Tentou avançar para fora da água. 
		# Para exatamente na borda.
		fight_base_position = (
			_find_last_fishable_position(
				fight_base_position,
				desired_base_position
			)
		)
		
		# Importante:
		# O progresso excedente NÃO fica armazenado.
		# Recalculamos qual progresso visual corresponde à posição real da borda.
		var travelled_distance: float = (
			(fight_base_position - fight_origin_position).dot(direction_to_rod)
		)
		
		fight_visual_progress = clampf(
			travelled_distance / travel_distance,
			0.0,
			1.0
		)
	
	# Borda
	# Usamos a direção do player para entender qual lado da margem está bloqueando.
	var edge_target_position: Vector2 = (
		fight_base_position + direction_to_rod * edge_detection_distance
	)
	
	var detected_edge_axis: Vector2 = (
		_detect_edge_axis(fight_base_position, edge_target_position)
	)
	
	var final_position: Vector2 = fight_base_position
	
	if detected_edge_axis != Vector2.ZERO:
		final_position = _get_edge_position(
			fight_base_position,
			detected_edge_axis,
			delta
		)
	
	else:
		_reset_edge_movement()
		
	# Suavização
	var follow_weight: float = (
		1.0
		- exp(-fight_position_response * delta)
	)
	
	var smoothed_position: Vector2 = (
		global_position.lerp(final_position, follow_weight)
	)
	
	if _is_fishable(smoothed_position):
		global_position = smoothed_position
	else:
		global_position = final_position
	
func _finish_throw() -> void:
	is_throwing = false
	is_landed = true
	
	global_position = target_position

	_set_detection_enabled(true)

	fishing_line.set_mode(
		FishingLine.LineMode.WAITING
	)
	
	play_water_ripple(1.0)
	_sync_bobber_idle_to_water()

	landed.emit(global_position)

func _sync_bobber_idle_to_water() -> void:
	if animation_player == null:
		return
	
	if water_animation_duration <= 0.0:
		return
	
	# Tempo global desde que o jogo iniciou:
	var global_time: float = float(Time.get_ticks_msec() / 1000.0)
	
	# Descobre em qual ponto do ciclo da água estamos neste exato momento.
	var animation_position: float = fposmod(
		global_time + water_animation_phase_offset,
		water_animation_duration
	)
	
	animation_player.play(bobber_idle_animation)
	
	animation_player.seek(animation_position, true)
	
# RETURN
func start_returning(
	target_provider: Callable,
	duration: float = -1.0
) -> void:
	fight_splash.emitting = false
	is_fight_positioning = false
	
	_reset_edge_movement()
	
	stop_bobber_visual()
	stop_water_ripple()
	
	if not target_provider.is_valid():
		remove_bobber()
		return

	return_target_provider = target_provider

	if duration > 0.0:
		return_duration = duration
	else:
		return_duration = default_return_duration
	
	return_duration = maxf(
		return_duration,
		0.01
	)
	
	return_start_position = global_position
	return_elapsed = 0.0
	
	is_throwing = false
	is_landed = false
	is_returning = true
	
	_set_detection_enabled(false)
	
	fishing_line.set_mode(
		FishingLine.LineMode.RETURNING
	)

func _update_returning(delta: float) -> void:
	if not return_target_provider.is_valid():
		remove_bobber()
		return
		
	stop_bobber_visual()
	
	return_elapsed += delta

	var progress: float = clampf(
		return_elapsed / return_duration,
		0.0,
		1.0
	)

	var eased_progress: float = smoothstep(
		0.0,
		1.0,
		progress
	)

	var current_target: Vector2 = (
		return_target_provider.call()
	)
	
	current_target.y += return_target_height
	
	var base_position: Vector2 = return_start_position.lerp(
		current_target, eased_progress
	)
	
	var arc_offset: float = (
		sin(progress * PI) * return_arc_height
	)
	
	global_position = (
		base_position
		+ Vector2.UP * arc_offset
	)

	fishing_line.set_return_progress(progress)

	if progress >= 1.0:
		global_position = current_target
		
		return_finished.emit()
		remove_bobber()

# LINE MODES
func set_line_waiting() -> void:
	is_fight_positioning = false
	
	_reset_edge_movement()
	
	if is_instance_valid(fight_splash):
		fight_splash.emitting = false
		
	if not is_instance_valid(fishing_line):
		return
	
	fishing_line.set_mode(
		FishingLine.LineMode.WAITING
	)
	

func set_line_fighting() -> void:
	if not is_instance_valid(fishing_line):
		return
		
	stop_bobber_visual()
	stop_water_ripple()
	
	fishing_line.set_mode(
		FishingLine.LineMode.FIGHTING
	)
	
	# Local onde o peixe foi fisgado.
	fight_origin_position = global_position
	fight_base_position = global_position
	
	# O deslocamento visual começa em Zero. 
	fight_progress_target = 0.0
	fight_previous_progress_target = 0.0
	fight_visual_progress = 0.0
	
	is_fight_positioning = true
	
	_reset_edge_movement()
	
	fight_splash.emitting = true

func set_fight_progress(progress: float) -> void:
	fight_progress_target = clampf(progress, 0.0, 1.0)

# HELPERS
func get_line_end_position() -> Vector2:
	return bobber_sprite.global_position + line_end_offset


func _set_detection_enabled(enabled: bool) -> void:
	if detection_area == null:
		return

	detection_area.monitoring = enabled
	detection_area.monitorable = enabled

	var collision_shape := (
		detection_area.get_node_or_null("CollisionShape2D")
		as CollisionShape2D
	)

	if collision_shape != null:
		collision_shape.set_deferred(
			"disabled",
			not enabled
		)

func remove_bobber() -> void:
	fight_splash.emitting = false
	is_fight_positioning = false
	
	_reset_edge_movement()
	
	if is_queued_for_deletion():
		return

	is_throwing = false
	is_returning = false
	is_landed = false

	_set_detection_enabled(false)

	if is_instance_valid(fishing_line):
		fishing_line.hide_line()

	removed.emit()
	
	stop_bobber_visual()
	
	queue_free()

func _on_water_ripple_finished() -> void:
	water_ripple.visible = false

func _is_fishable(world_position: Vector2) -> bool:
	if not fishable_position_provider.is_valid():
		return true
		
	return bool(
		fishable_position_provider.call(world_position)
	)
	
func _find_last_fishable_position(from_position: Vector2, to_position: Vector2) -> Vector2:
	if not _is_fishable(from_position):
		return global_position
	
	if _is_fishable(to_position):
		return to_position
		
	var valid_position: Vector2 = from_position
	var invalid_position: Vector2 = to_position
	
	# Busca binaria pela borda.
	for _index in range(10):
		var middle_position: Vector2 = (
			valid_position.lerp(invalid_position, 0.5)
		)
		if _is_fishable(middle_position):
			valid_position = middle_position
		else:
			invalid_position = middle_position
		
	return valid_position

func _detect_edge_axis(base_position: Vector2, desired_position: Vector2) -> Vector2:
	var probe: float = edge_detection_distance
	
	var can_up: bool = _is_fishable(base_position + Vector2.UP * probe)
	
	var can_down: bool = _is_fishable(base_position + Vector2.DOWN * probe)
	
	var can_left: bool = _is_fishable(base_position + Vector2.LEFT * probe)
	
	var can_right: bool = _is_fishable(base_position + Vector2.RIGHT * probe)
	
	var horizontal_blocked: bool = not can_left or not can_right
	var vertical_blocked: bool = not can_up or not can_down
	
	# Borda Esquerda/Direita
	# Movimentação Vertical
	if horizontal_blocked and not vertical_blocked:
		return Vector2.DOWN
		
	# Borda Superior / Inferior
	# Movimentação Horizontal
	
	if vertical_blocked and not horizontal_blocked:
		return Vector2.RIGHT
		
	# Quina
	
	if horizontal_blocked and vertical_blocked:
		var movement_to_target: Vector2 = desired_position - base_position
		
		# O peixe estava tentando sair principalmetne pela esquerda/direita.
		# Então desliza verticalmente.
		if absf(movement_to_target.x) > absf(movement_to_target.y):
			return Vector2.DOWN
			
		# Tentava sair por cima/baixo.
		# Então desliza horizontalmente.
		if absf(movement_to_target.y) > absf(movement_to_target.x):
			return Vector2.RIGHT
			
		# Empate.
		# Escolhemos o eixo com mais liberdade.
		var vertical_options: int = 0
		var horizontal_options: int = 0
		
		if can_up:
			vertical_options += 1
		
		if can_down:
			vertical_options += 1
		
		if can_left:
			horizontal_options += 1
			
		if can_right:
			horizontal_options += 1
			
		if vertical_options > horizontal_options:
			return Vector2.DOWN
		
		if horizontal_options > vertical_options:
			return Vector2.RIGHT
			
		# Ultimo desempate.
		if randf() < 0.5:
			return Vector2.RIGHT
	
	return Vector2.ZERO
		
		
func _get_edge_position(
	base_position: Vector2,
	detected_axis: Vector2,
	delta: float
) -> Vector2:
	
	# Entrou na borda pela priomeira vez ou mudou de tipo de borda.
	if not edge_active or edge_axis != detected_axis:
		edge_active = true
		edge_axis = detected_axis
		edge_offset = 0.0
		
		# Pode começar para qualquer um dos dois lados. 
		edge_direction = (
			-1.0
			if randf() < 0.5
			else 1.0
		)
	
	var minimum_offset: float
	var maximum_offset: float
	
	# Movimento Vertical	
	# negativo = cima
	# positivo = baixo
	
	if edge_axis == Vector2.DOWN:
		minimum_offset = -edge_limit_up
		maximum_offset = edge_limit_down
		
	# Movimento Horizontal
	# negativo = esquerda
	# positivo = direita
	
	else:
		minimum_offset = -edge_limit_left
		maximum_offset = edge_limit_right
		
	var movement_amount: float = (
		edge_move_speed
		* delta * edge_direction
	)
		
	var next_offset: float = edge_offset + movement_amount
	
	# Limites Artificais
	if next_offset >= maximum_offset:
		next_offset = maximum_offset
		edge_direction = -1.0
		
	elif next_offset <= minimum_offset:
		next_offset = minimum_offset
		edge_direction = 1.0
		
	var candidate_position: Vector2 = base_position + edge_axis * next_offset
	
	# Limite Real no fishable
	if not _is_fishable(candidate_position):
		# Encontrou outra parte da margem.
		# Inverte a direção
		edge_direction *= -1.0
		
		next_offset = edge_offset + edge_move_speed * delta * edge_direction
		next_offset = clampf(next_offset, minimum_offset, maximum_offset)
		
		candidate_position = base_position + edge_axis * next_offset
		
		# Se também não puder ir para o outro lado, tenta voltar para o centro.
		if not _is_fishable(candidate_position):
			next_offset = move_toward(
				edge_offset, 0.0, edge_move_speed * delta
			)
			
			candidate_position = base_position + edge_axis * next_offset
			
			# Se até o retorno estiver bloqueado, permanece na posição base
			if not _is_fishable(candidate_position):
				next_offset = 0.0
				candidate_position = base_position
				
	edge_offset = next_offset

	return candidate_position
		
func _reset_edge_movement() -> void:
	edge_active = false
	edge_axis = Vector2.ZERO
	edge_direction = 1.0
	edge_offset = 0.0

func freeze_fight_position() -> void:
	is_fight_positioning = false
	
	_reset_edge_movement()
	
	if is_instance_valid(fight_splash):
		fight_splash.emitting = false
	
func show_caught_fish() -> void:
	if caught_fish_visual == null:
		return
	
	caught_fish_visual.visible = true
	
	
	
	
	
		
