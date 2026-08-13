class_name CharacterCreator
extends Control

enum CreatorMenu {
	MAIN,
	BODY,
	HAIR,
	OUTFIT
}

# REFERENCES
@onready var name_popup: Control = $NamePopup
@onready var character_visual: Node2D = $CharacterVisual
@onready var turn_panel: Control = $TurnPanel
@onready var left_panel: Control = $LeftPanel
@onready var right_panel: RightPanel = $RightPanel

# OPTIONS
@export_category("Character Options")

@export var body_options: Array[BodyData] = []
@export var hair_options: Array[HairData] = []
@export var outfit_options: Array[OutfitData] = []

# CHARACTER DATA 
var appearance := CharacterAppearanceData.new()

# NAVIGATION
var current_menu: CreatorMenu = CreatorMenu.MAIN
var edit_snapshots: Array[CharacterAppearanceData] = []

# NAME EDITING
var customization_started: bool = false

var editing_existing_name: bool = false
var nickname_before_edit : String = ""


func _ready() -> void:
	setup_creator()
	
	right_panel.setup_options(
		hair_options,
		outfit_options
	)
	
	connect_signals()
	
	name_popup.open()

func setup_creator() -> void:
	character_visual.hide()
	
	left_panel.hide()
	right_panel.hide()
	turn_panel.hide()
	
	current_menu = CreatorMenu.MAIN

func connect_signals() -> void:
	
	# NAME
	name_popup.nickname_confirmed.connect(_on_nickname_confirmed)
	left_panel.edit_name_requested.connect(_on_edit_name_requested)
	
	# LEFT PANEL
	left_panel.body_requested.connect(_on_body_requested)
	left_panel.hair_requested.connect(_on_hair_requested)
	left_panel.outfit_requested.connect(_on_outfit_requested)
	
	# CHARACTER ROTATION
	turn_panel.turn_left_requested.connect(_on_turn_left_requested)
	turn_panel.turn_right_requested.connect(_on_turn_right_requested)
	
	# RIGHT PANEL - CHARACTER VALUES
	right_panel.body_type_requested.connect(_on_body_type_requested)
	right_panel.skin_color_selected.connect(_on_skin_color_selected)
	right_panel.eye_color_selected.connect(_on_eye_color_selected)
	right_panel.hair_requested.connect(_on_hair_requested_from_grid)
	right_panel.hair_color_selected.connect(_on_hair_color_selected)
	right_panel.hair_accessory_color_selected.connect(_on_hair_accessory_color_selected)
	right_panel.outfit_requested.connect(_on_outfit_requested_from_grid)
	
	# RIGHT PANEL - EDIT CONTROL
	right_panel.edit_started.connect(_on_right_panel_edit_started)
	right_panel.edit_confirmed.connect(_on_right_panel_edit_confirmed)
	right_panel.edit_cancelled.connect(_on_right_panel_edit_cancelled)
	right_panel.closed.connect(_on_right_panel_closed)
	
# START CUSTOMIZATION
func open_customization() -> void:
	customization_started = true
	
	set_default_character()
	
	character_visual.show()
	left_panel.show()
	turn_panel.show()
	
	current_menu = CreatorMenu.MAIN
	
	character_visual.start_idle()

# NAME
func _on_nickname_confirmed(nickname: String) -> void:
	var clean_name: String = nickname.strip_edges()
	
	if clean_name.is_empty():
		return
	
	appearance.character_name = clean_name
	
	name_popup.hide()
	
	left_panel.set_nickname(appearance.character_name)
	
	editing_existing_name = false
	nickname_before_edit = ""
	
	if not customization_started:
		open_customization()
	
	print("Nickname: ", appearance.character_name)
	
func _on_edit_name_requested() -> void:
	editing_existing_name = true
	
	nickname_before_edit = appearance.character_name
	
	name_popup.open(appearance.character_name)
	
func cancel_name_edit() -> void:
	if not customization_started:
		return
	
	if not editing_existing_name:
		return
		
	appearance.character_name = nickname_before_edit
	
	left_panel.set_nickname(appearance.character_name)
	
	editing_existing_name = false
	nickname_before_edit = ""
	
	name_popup.hide()

# EDIT HISTORY
func push_edit_snapshot() -> void:
	var snapshot := appearance.duplicate(true) as CharacterAppearanceData
	
	if snapshot == null:
		push_error(
			"CharacterCreator: não foi possível criar snapshot."
		)
		return
	
	edit_snapshots.append(snapshot)
	
func confirm_current_edit() -> void:
	if edit_snapshots.is_empty():
		return
	
	edit_snapshots.pop_back()

func cancel_current_edit() -> void:
	if edit_snapshots.is_empty():
		return
	
	var previous_appearance: CharacterAppearanceData = (
		edit_snapshots.pop_back()
	)
	
	appearance = previous_appearance
	
	apply_complete_appearance()
	
# MAIN MENU BUTTONS
func _on_body_requested() -> void:
	push_edit_snapshot()
	
	current_menu = CreatorMenu.BODY
	
	sync_colors()
	
	right_panel.open_body()

func _on_hair_requested() -> void:
	push_edit_snapshot()
	
	current_menu = CreatorMenu.HAIR
	
	sync_colors()
	
	var hair_data := get_hair_data_by_id(appearance.hair_id)
	
	if hair_data != null:
		right_panel.set_hair_accessory_available(hair_data.has_accessory)
		
	else:
		right_panel.set_hair_accessory_available(false)
	
	right_panel.open_hair(appearance.hair_id)

func _on_outfit_requested() -> void:
	push_edit_snapshot()
	
	current_menu = CreatorMenu.OUTFIT
	
	right_panel.set_outfit_body_type(appearance.body_id)
	
	right_panel.open_outfit(appearance.outfit_id)

# BODY
func _on_body_type_requested(body_type: int) -> void:
	var body_data : BodyData = get_body_data_by_id(body_type)
	
	if body_data == null:
		push_warning("BodyData não encontrado para ID: %s" % body_type)
		return
	
	appearance.body_id = body_data.id
	
	character_visual.set_body_type(body_data)
	
	right_panel.set_outfit_body_type(appearance.body_id)
	
	var outfit_data := get_outfit_data_by_id(appearance.outfit_id)
	
	if outfit_data != null:
		character_visual.set_outfit(outfit_data, appearance.body_id)

func _on_skin_color_selected(color: Color) -> void:
	appearance.skin_color = color
	
	character_visual.set_skin_color(color)

func _on_eye_color_selected(color: Color) -> void:
		appearance.eye_color = color
		
		character_visual.set_eye_color(color)

# HAIR
func _on_hair_requested_from_grid(hair_id: int) -> void:
	var hair_data: HairData = get_hair_data_by_id(hair_id)
	
	if hair_data == null:
		push_warning("HairData não encontrado para ID: %s" % hair_id)
		return
	
	appearance.hair_id = hair_data.id
	
	character_visual.set_hair(hair_data)
	
	right_panel.set_hair_accessory_available(hair_data.has_accessory)
	
func _on_hair_color_selected(color: Color) -> void:
	appearance.hair_color = color
	
	character_visual.set_hair_color(color)
	
func _on_hair_accessory_color_selected(color: Color) -> void:
	appearance.hair_accessory_color = color
	
	character_visual.set_hair_accessory_color(color)
	
# OUTFIT
func _on_outfit_requested_from_grid(outfit_id: int) -> void:
	var outfit_data: OutfitData = get_outfit_data_by_id(outfit_id)
	
	if outfit_data == null:
		push_warning("OutfitData não encontrado para ID: %s" % outfit_id)
		return
		
	appearance.outfit_id = outfit_data.id
	
	character_visual.set_outfit(outfit_data, appearance.body_id)

# RIGHT PANEL EDIT EVENTS
func _on_right_panel_edit_started() -> void:
	push_edit_snapshot()

func _on_right_panel_edit_confirmed() -> void:
	confirm_current_edit()

func _on_right_panel_edit_cancelled() -> void:
	cancel_current_edit()
	
func _on_right_panel_closed() -> void:
	current_menu = CreatorMenu.MAIN
	
# BACK / ESC
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	
	if name_popup.visible:
		cancel_name_edit()
		
		get_viewport().set_input_as_handled()
		return
	
	if right_panel.visible:
		var handled: bool = right_panel.request_back()
		
		if handled:
			get_viewport().set_input_as_handled()
			
		return
		
# TURN CHARACTER
func _on_turn_left_requested() -> void:
	character_visual.turn_left()

func _on_turn_right_requested() -> void:
	character_visual.turn_right()

# DATA LOOKUP
func get_body_data_by_id(body_id: int) -> BodyData:
	for body_data in body_options:
		if body_data != null and body_data.id == body_id:
			return body_data
			
	return null
	
func get_hair_data_by_id(hair_id: int) -> HairData:
	for hair_data in hair_options:
		if hair_data != null and hair_data.id == hair_id:
			return hair_data
			
	return null

func get_outfit_data_by_id(outfit_id: int) -> OutfitData:
	for outfit_data in outfit_options:
		if outfit_data != null and outfit_data.id == outfit_id:
			return outfit_data
			
	return null

# APPLY APPEARANCE
func apply_complete_appearance() -> void:
	var body_data: BodyData = get_body_data_by_id(appearance.body_id)
	
	if body_data != null:
		character_visual.set_body_type(body_data)
	
	var hair_data: HairData = get_hair_data_by_id(appearance.hair_id)
	
	if hair_data != null:
		character_visual.set_hair(hair_data)
		
	var outfit_data : OutfitData = get_outfit_data_by_id(appearance.outfit_id)
	
	if outfit_data != null:
		character_visual.set_outfit(outfit_data, appearance.body_id)
		
	character_visual.set_skin_color(appearance.skin_color)
	character_visual.set_eye_color(appearance.eye_color)
	character_visual.set_hair_color(appearance.hair_color)
	character_visual.set_hair_accessory_color(appearance.hair_accessory_color)
	
	sync_colors()
	
# DEFAULT CHARACTER
func set_default_character() -> void:
	appearance.body_id = 1
	appearance.hair_id = 1
	appearance.outfit_id = 1
	
	appearance.skin_color = Color("#F1C5A3")
	appearance.eye_color = Color("#4CB528")
	appearance.hair_color = Color("#5D2C28")
	appearance.hair_accessory_color = Color("#7E97CA")
	
	apply_complete_appearance()

func sync_colors() -> void:
	right_panel.sync_colors_from_appearance(
		appearance.skin_color,
		appearance.eye_color,
		appearance.hair_color,
		appearance.hair_accessory_color
	)
