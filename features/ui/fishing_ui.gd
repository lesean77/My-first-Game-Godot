class_name FishingUI
extends CanvasLayer

# SIGNALS
signal fish_contact_changed(is_inside: bool)

# CATCH BAR SETTINGS
@export_category("Catch Bar")

# Velocidade máxima para a direita enquanto RMB está pressionado.
@export var push_speed: float = 120.0

# Velocidade máxima de retorno para a esquerda.
@export var return_speed: float = 90.0

# Aceleração enquanto pressionado RMB.
@export var push_acceleration: float = 320.0

# Aceleração do retorno para a esquerda.
@export var return_acceleration: float = 320.0

# Espaço interno da pista.
@export var track_left_padding: float = 5.0
@export var track_right_padding: float = 5.0

# FISH START POSITION
@export_category("Fish")
@export_range(0.0, 1.0) var fish_spawn_min_ratio: float = 0.20
@export_range(0.0, 1.0) var fish_spawn_max_ratio: float = 0.80

# FISH MOVEMENT
@export_category("Fish Movement")
# Velocidade normal do peixe.
@export var fish_speed: float = 45.0

# Quanto tempo leva para atingar a velocidade desejada. 
@export var fish_acceleration: float = 140.0

# Quanto o comportamento do peixe é imprevisível.
# 0 - previsível.
# 1 - muito errático.
@export_range(0.0, 1.0) var fish_randomness: float = 0.65

# Intervalo entre decisões de movimento
@export var fish_min_direction_time: float = 0.35
@export var fish_max_direction_time: float = 1.10

# Chance de o peixe ficar parado por alguns instantes.
@export_range(0.0, 1.0) var fish_pause_chance: float = 0.10

# Chance de fazer um movimento rápido
@export_range(0.0, 1.0) var fish_burst_chance: float = 0.08

# Multiplicador de velocidade durante um burst
@export var fish_burst_multiplier: float = 1.55

@export_category("Fish Start")
# Distância mínima da CatchBar ao nascer.
# Evita que todo peixe comece exatamente dentro dela.
@export var fish_spawn_min_distance: float = 8.0

# Distância máxima entre o centro da CatchBar e o peixe.
@export var fish_spawn_max_distance: float = 35.0

# SHAKE
@export_category("Miss Shake")
# Tempo errando antes do shake começar.
@export var miss_shake_delay: float = 1.0
# Intensidade máxima em pixels.
@export var miss_shake_strength: float = 1.5
# Velocidade da tremida.
@export var miss_shake_speed: float = 22.0

# PROGRESS COLORS
@export_category("Progress Colors")

@export var progress_red: Color = Color("#c30003")
@export var progress_orange: Color = Color("#ef611e")
@export var progress_yellow: Color = Color("#deac28")
@export var progress_green: Color = Color("#40ff33")

# FEEDBACK GLOW
@export_category("Feedback Glow")
@export var hit_glow_color: Color = Color(0.20, 1.0, 0.20, 0.20)
@export var miss_glow_color: Color = Color(1.0, 0.12, 0.12, 0.20)

# Quantidade de pulsações por segundo.
@export var miss_pulse_speed: float = 1.25

# Alpha mínimo durante o pulse vermelho.
@export_range(0.0, 1.0) var miss_min_alpha: float = 0.025

# REFERENCES
@onready var bite_label: Label = $BiteLabel

# NEW PROGRESS UI
@onready var progress_panel: Panel = $Panel
@onready var capture_progress_bar: TextureProgressBar = $Panel/TextureProgressBar

# NEW FISHING GAME UI
@onready var fight_container: Panel = $PanelContainer
@onready var fight_track: NinePatchRect = $PanelContainer/NinePatchRect
@onready var catch_bar: Panel = $PanelContainer/NinePatchRect/FightBar
@onready var fish_anchor: Node2D = $PanelContainer/NinePatchRect/FishIcon
@onready var fish_sprite: Sprite2D = $PanelContainer/NinePatchRect/FishIcon/Sprite2D
@onready var feedback_glow: ColorRect = (
	get_node_or_null("PanelContainer/NinePatchRect/FeedbackGlow") as ColorRect
)

@onready var track_material: ShaderMaterial = fight_track.material as ShaderMaterial
@onready var glow_material: ShaderMaterial = feedback_glow.material as ShaderMaterial

# POWER BAR
@onready var power_panel: Panel = $PowerPanel
@onready var power_bar: ProgressBar = $PowerPanel/PowerBar

# TIMER
@onready var message_timer: Timer = $MessageTimer

# RESULT
@export_category("Result")
@export var result_hold_duration: float = 1.0

# RUNTIME
var fight_active: bool = false

var catch_bar_velocity: float = 0.0

var miss_pulse_time: float = 0.0
var miss_duration: float = 0.0
var miss_shake_time: float = 0.0

var fight_track_base_position: Vector2 = Vector2.ZERO
var current_fight_progress: float = 0.0

var last_fish_inside: bool = false

var fish_velocity: float = 0.0
var fish_target_velocity: float = 0.0
var fish_direction_timer: float = 0.0

# READY
func _ready() -> void:
	fight_track_base_position = fight_track.position
	
	_clear_fishing_ui()
	
	if not message_timer.timeout.is_connected(hide_result_message):
		message_timer.timeout.connect(hide_result_message)
	
func _clear_fishing_ui() -> void:
	fight_active = false
	
	catch_bar_velocity = 0.0
	
	miss_pulse_time = 0.0
	miss_duration = 0.0
	miss_shake_time = 0.0
	
	current_fight_progress = 0.0
	
	fight_track.position = fight_track_base_position
	
	message_timer.stop()
	
	bite_label.hide()
	power_panel.hide()
	progress_panel.hide()
	fight_container.hide()
	
	if feedback_glow != null:
		feedback_glow.color = Color.TRANSPARENT

func _stop_miss_shake() -> void:
	miss_duration = 0.0
	miss_shake_time = 0.0
	
	fight_track.position = fight_track_base_position
	
# PROCESS
func _process(delta: float) -> void:
	if not fight_active:
		return
		
	_update_catch_bar(delta)
	_update_fish_movement(delta)
	
	var fish_inside: bool = _is_fish_inside_catch_bar()
	
	_update_feedback_glow(delta, fish_inside)
	_update_miss_shake(delta, fish_inside)
	
	if fish_inside != last_fish_inside:
		last_fish_inside = fish_inside
		
		fish_contact_changed.emit(fish_inside)
		
# SETUP
func setup(player_fishing: PlayerFishing) -> void:
	var contact_callable := Callable(
		player_fishing,
		"set_fish_in_catch_bar"
	)
	
	if not fish_contact_changed.is_connected(contact_callable):
		fish_contact_changed.connect(contact_callable)
		
	if not player_fishing.cast_started.is_connected(show_power_bar):
		player_fishing.cast_started.connect(show_power_bar)
		
	if not player_fishing.cast_power_changed.is_connected(update_power_bar):
		player_fishing.cast_power_changed.connect(update_power_bar)
		
	if not player_fishing.cast_power_finished.is_connected(fishing_power_bar):
		player_fishing.cast_power_finished.connect(fishing_power_bar)
		
	if not player_fishing.bite_indicator_shown.is_connected(show_bite_indicator):
		player_fishing.bite_indicator_shown.connect(show_bite_indicator)
		
	if not player_fishing.bite_indicator_hidden.is_connected(hide_bite_indicator):
		player_fishing.bite_indicator_hidden.connect(hide_bite_indicator)
		
	if not player_fishing.fishing_fight_started.is_connected(show_fighting_ui):
		player_fishing.fishing_fight_started.connect(show_fighting_ui)
		
	if not player_fishing.fight_values_changed.is_connected(update_fighting_ui):
		player_fishing.fight_values_changed.connect(update_fighting_ui)
		
	if not player_fishing.fish_caught.is_connected(show_capture_message):
		player_fishing.fish_caught.connect(show_capture_message)
	
	if not player_fishing.fish_escaped.is_connected(show_escape_message):
		player_fishing.fish_escaped.connect(show_escape_message)
		
	if not player_fishing.fishing_cancelled.is_connected(hide_fishing_ui):
		player_fishing.fishing_cancelled.connect(hide_fishing_ui)
		
# POWER BAR
func show_power_bar() -> void:
	power_bar.value = 0.0
	
	power_panel.show()
	
func update_power_bar(power: float) -> void:
	power_bar.value = power * 100.0

func fishing_power_bar(power: float) -> void:
	power_bar.value = power * 100.0
	
	power_panel.hide()
	
# BITE
func show_bite_indicator() -> void:
	message_timer.stop()
	
	bite_label.text = "PUXOU!!!"
	bite_label.show()
	
func hide_bite_indicator() -> void:
	bite_label.hide()
	
# START FIGHT
func show_fighting_ui() -> void:
	power_panel.hide()
	bite_label.hide()
	
	capture_progress_bar.value = 0.0
	
	_update_progress_color(0.0)
	
	progress_panel.show()
	fight_container.show()
	
	call_deferred("_start_fight_visuals")

func _start_fight_visuals() -> void:
	catch_bar_velocity = 0.0
	
	fish_velocity = 0.0
	fish_target_velocity = 0.0
	fish_direction_timer = 0.0
	
	miss_pulse_time = 0.0
	
	_center_catch_bar()
	_randomize_fish_start()
	
	_choose_new_fish_motion()
	
	last_fish_inside = _is_fish_inside_catch_bar()
	
	_update_feedback_glow(0.0, last_fish_inside)
	
	fight_active = true
	
	fish_contact_changed.emit(last_fish_inside)
	
# CATCH BAR
func _center_catch_bar() -> void:
	var min_x: float = track_left_padding
	
	var max_x: float = (fight_track.size.x - track_right_padding - catch_bar.size.x)
	
	catch_bar.position.x = (min_x + max_x) * 0.5


func _update_catch_bar(delta: float) -> void:
	var target_velocity: float
	
	# LMB pressionado = direita
	if Input.is_action_pressed("attack"):
		target_velocity = push_speed
		
		catch_bar_velocity = move_toward(
			catch_bar_velocity,
			target_velocity,
			push_acceleration * delta
		)
		
		# LMB solto = esquerda
	else:
		target_velocity = -return_speed
			
		catch_bar_velocity = move_toward(
			catch_bar_velocity,
			target_velocity,
			return_acceleration * delta
		)

	var min_x: float = track_left_padding
	
	var max_x: float = (fight_track.size.x - track_right_padding - catch_bar.size.x)
	
	var new_x: float = (catch_bar.position.x + catch_bar_velocity * delta)
	
	new_x = clampf(new_x, min_x, max_x)
	
	catch_bar.position.x = new_x
	
	# Impede a velocidade de continuar acumulando contra as paredes.
	
	if (new_x <= min_x and catch_bar_velocity < 0.0):
		catch_bar_velocity = 0.0
	
	elif (new_x >= max_x and catch_bar_velocity > 0.0):
		catch_bar_velocity = 0.0
		
func _update_miss_shake(delta: float, fish_inside: bool) -> void:
	# ACERTOU
	if fish_inside:
		miss_duration = 0.0
		miss_shake_time = 0.0
		
		fight_track.position = fight_track_base_position
		
		return
	
	# ERROU
	miss_duration += delta
	
	# Ainda não chegou ao tempo necessário.
	if miss_duration < miss_shake_delay:
		fight_track.position = fight_track_base_position
		return
		
	# SHAKE
	miss_shake_time += delta * miss_shake_speed
	
	var shake_x: float = sin(miss_shake_time)
	var shake_y: float = sin(miss_shake_time * 1.73)
	var shake_offset := Vector2(shake_x, shake_y) * miss_shake_strength
	
	# Manter efeito pixel
	shake_offset.x = roundf(shake_offset.x)
	shake_offset.y = roundf(shake_offset.y)
	
	fight_track.position = fight_track_base_position + shake_offset
		
# FISH POSITION
func _randomize_fish_start() -> void:
	var catch_center_x: float = (
		catch_bar.position.x
		+ catch_bar.size.x * 0.5
	)
	
	var half_fish_width: float = _get_fish_half_width()
	
	var min_track_x: float = track_left_padding + half_fish_width
	var max_track_x: float = fight_track.size.x - track_right_padding - half_fish_width
	
	# Sorteia uma distância relativamente pequena.
	var spawn_distance: float = randf_range(
		fish_spawn_min_distance,
		fish_spawn_max_distance
	)
	
	# Escolhe esquerda ou direita.
	var direction: float = (
		-1.0
		if randf() < 0.5
		else 1.0
	)
	
	var spawn_x: float = (
		catch_center_x + spawn_distance * direction
	)
	
	# Nunca deixa sair da pista
	spawn_x = clampf(spawn_x, min_track_x, max_track_x)
	
	fish_anchor.position.x = spawn_x
	
	fish_sprite.position.x = 0.0
	fish_sprite.position.y = fight_track.size.y * 0.5

# FISH / CATACH BAR CONTACT
func _is_fish_inside_catch_bar() -> bool:
	var fish_center_x: float = fish_anchor.position.x
	
	var catch_left: float = catch_bar.position.x
	var catch_right: float = catch_bar.position.x + catch_bar.size.x
	
	return fish_center_x >= catch_left and fish_center_x <= catch_right

func _update_fish_movement(delta: float) -> void:
	fish_direction_timer -= delta
	
	# Hora do peixe tomar uma nova decisão.
	if fish_direction_timer <= 0.0:
		_choose_new_fish_motion()
		
	# Acelera gradualmente até a velocidade desejada. 
	fish_velocity = move_toward(
		fish_velocity,
		fish_target_velocity,
		fish_acceleration * delta
	)
	
	fish_anchor.position.x += fish_velocity * delta
	
	var half_width: float = _get_fish_half_width()
	var min_x: float = track_left_padding + half_width
	var max_x: float = (fight_track.size.x - track_right_padding - half_width)
	
	# Borda esquerda
	if fish_anchor.position.x <= min_x:
		fish_anchor.position.x = min_x
		
		fish_velocity = absf(fish_velocity)
		
		fish_target_velocity = absf(fish_target_velocity)
		
	# Borda direita
	if fish_anchor.position.x >= max_x:
		fish_anchor.position.x = max_x
		
		fish_velocity = -absf(fish_velocity)
		
		fish_target_velocity = -absf(fish_target_velocity)

func _choose_new_fish_motion() -> void:
	# Tempo até a proxima decisão
	var random_time: float = randf_range(
		fish_min_direction_time,
		fish_max_direction_time
	)
	
	# Quanto menor randomness, mais tempo ele tende a manter o movimento
	fish_direction_timer = lerpf(
		fish_max_direction_time,
		random_time,
		fish_randomness
	)
	
	# Possibilidade de parar
	if randf() < fish_pause_chance * fish_randomness:
		fish_target_velocity = 0.0
		return
	
	# Direção
	var direction: float
	
	# Se ainda não estava se movendo, escolhe esquerda ou direita
	if is_zero_approx(fish_target_velocity):
		direction = (
			-1.0
			if randf() < 0.5
			else 1.0
		)
	
	# Peixe mais aleatório pode mudar de direção.
	elif randf() < fish_randomness:
		direction = (
			-1.0
			if randf() < 0.5
			else 1.0
		)
	 # Peixe mais previsível continua na mesma direção.
	else: 
		direction = signf(fish_target_velocity)
		
	# Variação de Velocidade
	var random_speed_factor: float = randf_range(0.55, 1.0)
	
	var speed_factor: float = lerpf(0.85, random_speed_factor, fish_randomness)
	
	# Burst
	if randf() < fish_burst_chance * fish_randomness:
		speed_factor *= fish_burst_multiplier
		
	fish_target_velocity = direction * fish_speed * speed_factor

func _get_fish_half_width() -> float:
	if fish_sprite.texture == null:
		return 0.0
	
	return (
		float(fish_sprite.texture.get_width())
		* absf(fish_sprite.scale.x)
		* 0.5
	)
	
# GLOW FEEDBACK
func _update_feedback_glow(delta: float, fish_inside: bool) -> void:
	if (track_material == null or glow_material == null):
		return
		
	# Acertando o peixe
	if fish_inside:
		miss_pulse_time = 0.0
		
		var hit_color := Color(0.30, 1.0, 0.18, 1.0)
		
		track_material.set_shader_parameter("status_color", hit_color)
		glow_material.set_shader_parameter("glow_color", hit_color)
		glow_material.set_shader_parameter("glow_strength", 0.65)
		
		return
	
	# Errando o peixe
	miss_pulse_time += delta
	
	var pulse: float = (
		sin(miss_pulse_time * miss_pulse_speed * TAU)
		+ 1.0
	) * 0.5
	
	# PERIGO
	# Progress alto = pouco perigo
	# Progress baixo = muito perigo
	var danger: float = 1.0 - current_fight_progress
	
	var miss_color := Color(1.0, 0.12, 0.08, 1.0)
	
	track_material.set_shader_parameter("status_color", miss_color)
	glow_material.set_shader_parameter("glow_color", miss_color)
	
	# Força base do blow
	var base_strength: float = lerpf(0.25, 0.80, danger)
	
	# O pulse também fica mais forte conforme o progress chega perto do zero
	var pulse_strength: float = lerpf(0.08, 0.20, danger)
	
	var strength: float = base_strength + pulse * pulse_strength
	
	strength = clampf(strength, 0.0, 1.0)
	
	glow_material.set_shader_parameter("glow_strength", strength)
	
# CAPTURE PROGRESS
func update_fighting_ui(progress: float) -> void:
	var normalized_progress: float = clampf(progress, 0.0, 1.0)
	
	current_fight_progress = normalized_progress
	
	capture_progress_bar.value = normalized_progress * 100.0
	
	_update_progress_color(normalized_progress)
	
func _update_progress_color(progress: float) -> void:
	var color: Color
	
	var first_section: float = 1.0 / 3.0
	var second_section: float = 2.0 / 3.0
	
	# Vermelho -> Laranja
	if progress <= first_section:
		var weight: float = progress / first_section
		
		color = progress_red.lerp(progress_orange, weight)
		
	# Laranja -> Amarelo
	elif progress <= second_section:
		var weight: float = (progress - first_section) / first_section
		
		color = progress_orange.lerp(progress_yellow, weight)
		
	# Amarelo -> Verde
	else: 
		var weight: float = (progress - second_section) / first_section
		
		color = progress_yellow.lerp(progress_green, weight)
		
	capture_progress_bar.tint_progress = color
	

# RESULT

func show_capture_message() -> void:
	fight_active = false
	
	_stop_miss_shake()
	
	catch_bar_velocity = 0.0
	fish_velocity = 0.0
	fish_target_velocity = 0.0
	
	capture_progress_bar.value = 100.0
	_update_progress_color(1.0)
	
	if feedback_glow != null:
		feedback_glow.color = hit_glow_color
		
	bite_label.text = "EXEMPLAR CAPTURADO!"
	bite_label.show()
	
	message_timer.start(result_hold_duration)
	
func show_escape_message() -> void:
	fight_active = false
	
	_stop_miss_shake()
	
	catch_bar_velocity = 0.0
	fish_velocity = 0.0
	fish_target_velocity = 0.0
	
	if feedback_glow != null:
		feedback_glow.color = miss_glow_color
	
	bite_label.text = "PUTZ, ESCAPOU!"
	bite_label.show()
	
	message_timer.start(result_hold_duration)
	
func hide_result_message() -> void:
	bite_label.hide()
	progress_panel.hide()
	fight_container.hide()

func hide_fishing_ui() -> void:
	_clear_fishing_ui()
	
