class_name PlayerAction
extends Node

signal action_finished

var player
var player_animation : PlayerAnimation
var player_attack
var player_farming : PlayerFarming
var player_fishing : PlayerFishing

var current_action : ActionType.Type = ActionType.Type.NONE
var current_target : Node = null
var current_equipment : EquipmentData = null

var effect_applied : bool = false

func setup(player_ref, animation_ref, attack_ref, farming_ref, fishing_ref) -> void:
	player = player_ref
	player_animation = animation_ref
	player_attack = attack_ref
	player_farming = farming_ref
	player_fishing = fishing_ref

func is_busy() -> bool:
	return current_action != ActionType.Type.NONE

# AÇÃO SEM EQUIPAMENTO
func perform_action(action_type : ActionType.Type, target : Node = null) -> void:
	if is_busy():
		return
	
	current_action = action_type
	current_target = target
	current_equipment = null
	effect_applied = false
	
	match current_action:
		ActionType.Type.ATTACK:
			player_animation.set_animation("Attack")
			
		ActionType.Type.CRUSH:
			player_animation.set_animation("Crush")
			
		ActionType.Type.SLICE:
			player_animation.set_animation("Slice")
			
		ActionType.Type.TILLING:
			player_animation.set_animation("Tilling")
			
		ActionType.Type.WATERING:
			player_animation.set_animation("Watering")
		
		ActionType.Type.COLLECTING:
			player_animation.set_animation("Collect")
			
		ActionType.Type.FISHING:
			player_animation.set_animation("Fishing")
		
		ActionType.Type.HURT:
			player_animation.set_animation("Hurt")
			
		ActionType.Type.DEATH:
			player_animation.set_animation("Death")
			
		_:
			push_warning(
				"Ação sem animação configurada: %s"
				% ActionType.Type.keys()[current_action]
			)
			
			finish_action()
			
			
# AÇÃO COM EQUIPAMENTO
func perform_equipment_action(equipment: EquipmentData) -> void:
	if is_busy():
		return
		
	if equipment == null:
		push_warning("Não foi possível realizar a ação: equipamento nulo.")
		return
	
	if equipment.animation_name.is_empty():
		push_warning(
			"Equipamento sem animation_name: %s"
			% equipment.display_name
		)
		return
	
	current_action = equipment.action_type
	current_target = null
	current_equipment = equipment
	effect_applied = false
	
	print(
		"Iniciando ação com equipamento: ",
		equipment.display_name,
		" | Ação: ",
		ActionType.Type.keys()[current_action],
		" | Animação: ",
		equipment.animation_name
	)
	
	match equipment.equipment_type:
		EquipmentData.EquipmentType.HOE:
			player_farming.lock_target()
			
		EquipmentData.EquipmentType.WATERING_CAN:
			player_farming.lock_target()
		
		_:
			pass
			
	if equipment.equipment_type == EquipmentData.EquipmentType.FISHING_ROD:
		player_fishing.cast_line(equipment)
		return
	
	player_animation.set_animation(
		String(equipment.animation_name)
	)

# EFEITOS CHAMADOS PELAS ANIMAÇÕES
func apply_action_effect() -> void:
	if current_action == ActionType.Type.NONE:
		return
		
	print(
		"apply_action_effect | ação: ",
		ActionType.Type.keys()[current_action]
	)
	
	if effect_applied:
		return
		
	effect_applied = true
	
	if current_equipment == null:
		apply_regular_action_effect()
		return
		
	apply_equipment_effect()

func apply_equipment_effect() -> void:
	if current_equipment == null: 
		return
		
	match current_equipment.equipment_type:
		EquipmentData.EquipmentType.PICKAXE:
			player_attack.apply_equipment_hit(current_equipment)
			
		EquipmentData.EquipmentType.AXE:
			player_attack.apply_equipment_hit(current_equipment)
			
		EquipmentData.EquipmentType.HOE:
			apply_hoe_effect(current_equipment)
			
		EquipmentData.EquipmentType.WATERING_CAN:
			apply_watering_effect(current_equipment)
			
		EquipmentData.EquipmentType.FISHING_ROD:
			apply_fishing_effect(current_equipment)
			
		EquipmentData.EquipmentType.SWORD:
			player_attack.apply_equipment_hit(current_equipment)
			
func apply_regular_action_effect() -> void:
	match current_action:
		ActionType.Type.COLLECTING:
			apply_collecting_effect()
		
		ActionType.Type.ATTACK:
			apply_default_attack_effect()
			
		_:
			pass

func apply_collecting_effect() -> void:
	if current_target == null:
		return
	
	if not is_instance_valid(current_target):
		return
	
	if current_target.has_method("collect"):
		current_target.collect(player)
	
func apply_watering_effect(equipment : EquipmentData) -> void:
	player_farming.water_ground(equipment)

func apply_fishing_effect(equipment: EquipmentData) -> void:
	player_fishing.cast_line(equipment)
	

func apply_hoe_effect(equipment: EquipmentData) -> void:
	player_farming.till_ground(equipment)
	
func apply_default_attack_effect() -> void:
	pass

# FINALIZAÇÃO
func finish_action() -> void:
	if current_action == ActionType.Type.NONE:
		return
		
	print(
		"finish_action | encerrando: ",
		ActionType.Type.keys()[current_action]
	)
	
	if current_equipment != null:
		match current_equipment.equipment_type:
			EquipmentData.EquipmentType.HOE:
				player_farming.unlock_target()
				
			EquipmentData.EquipmentType.WATERING_CAN:
				player_farming.unlock_target()
			
			_:
				pass
				
	if current_action == ActionType.Type.COLLECTING:
		player_farming.unlock_target()
	
	current_action = ActionType.Type.NONE
	current_target = null
	current_equipment = null
	effect_applied = false
	
	action_finished.emit()
	
