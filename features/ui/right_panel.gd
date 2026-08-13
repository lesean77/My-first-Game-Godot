class_name RightPanel
extends Control

# CHARACTER VALUE SIGNALS
signal body_type_requested(body_type: int)

signal hair_requested(hair_id: int)
signal outfit_requested(outfit_id: int)

signal skin_color_selected(color: Color)
signal eye_color_selected(color: Color)
signal hair_color_selected(color: Color)
signal hair_accessory_color_selected(color: Color)

# EDIT CONTROL SIGNALS
signal edit_started
signal edit_confirmed
signal edit_cancelled

signal closed

enum Section {
	NONE,
	BODY,
	HAIR,
	OUTFIT,
	COLOR,
	CUSTOM_COLOR
}

enum ColorTarget {
	NONE,
	SKIN,
	EYES,
	HAIR,
	HAIR_ACCESSORY
}

# REFERENCES
@onready var body_menu: BodyMenu = $BodyMenu
@onready var hair_menu: HairMenu = $HairMenu
@onready var outfit_menu: OutfitMenu = $OutfitMenu
@onready var color_menu: Colormenu = $ColorMenu
@onready var custom_color_menu: CustomColorMenu = $CustomColorMenu

# CURRENT STATE
var current_section : Section = Section.NONE

var color_parent_section: Section = Section.NONE

var current_color_target : ColorTarget = ColorTarget.NONE

# CURRENT COLORS
var current_skin_color : Color = Color("#F1C5A3")
var current_eye_color : Color = Color("#4CB528")
var current_hair_color : Color = Color("#5D2C28")
var current_hair_accessory_color : Color = Color("#7E97CA")

func _ready() -> void:
	hide_all_sections()
	
	# BODY
	body_menu.body_type_requested.connect(_on_body_type_requested)
	body_menu.skin_color_requested.connect(_on_skin_color_requested)
	body_menu.eye_color_requested.connect(_on_eye_color_requested)
	body_menu.confirm_requested.connect(_on_body_confirmed)
	
	# COLOR
	color_menu.color_selected.connect(_on_color_selected)
	color_menu.confirm_requested.connect(_on_color_confirmed)
	color_menu.custom_color_requested.connect(_on_custom_color_requested)
	
	# CUSTOM COLOR
	custom_color_menu.color_selected.connect(_on_custom_color_selected)
	custom_color_menu.confirm_requested.connect(_on_custom_color_confirmed)
	
	# HAIR
	hair_menu.hair_requested.connect(_on_hair_requested)
	hair_menu.hair_color_requested.connect(_on_hair_color_requested)
	hair_menu.accessory_color_requested.connect(_on_hair_accessory_color_requested)
	hair_menu.confirm_requested.connect(_on_hair_confirmed)
	
	# OUTFIT
	outfit_menu.outfit_requested.connect(_on_outfit_requested)
	outfit_menu.confirm_requested.connect(_on_outfit_confirmed)

func setup_options(
	hair_options: Array[HairData],
	outfit_options: Array[OutfitData]
) -> void:
	hair_menu.setup_hair_options(hair_options)
	outfit_menu.setup_outfit_options(outfit_options)
	
# SECTION VISIBILITY
func hide_all_sections() -> void:
	body_menu.hide()
	hair_menu.hide()
	outfit_menu.hide()
	color_menu.hide()
	custom_color_menu.hide()

func close() -> void:
	hide_all_sections()
	
	current_section = Section.NONE
	color_parent_section = Section.NONE
	current_color_target = ColorTarget.NONE
	
	hide()
	
	closed.emit()
	
func open_body() -> void:
	show()
	hide_all_sections()
	
	current_section = Section.BODY
	
	body_menu.show()
	
func open_hair(selected_hair_id: int = -1) -> void:
	show()
	hide_all_sections()
	
	current_section = Section.HAIR
	
	hair_menu.show()
	
	if selected_hair_id >= 0:
		hair_menu.set_selected_hair(selected_hair_id)
	
func open_outfit(selected_outfit_id: int = -1) -> void:
	show()
	hide_all_sections()
	
	current_section = Section.OUTFIT
	
	outfit_menu.show()
	if selected_outfit_id >= 0:
		outfit_menu.set_selected_outfit(selected_outfit_id)

# COLOR STATE
func sync_colors_from_appearance(
	skin_color: Color,
	eye_color: Color,
	hair_color: Color,
	hair_accessory_color: Color
) -> void:
	current_skin_color = skin_color
	current_eye_color = eye_color
	current_hair_color = hair_color
	current_hair_accessory_color = hair_accessory_color
	
	hair_menu.set_hair_color_preview(hair_color)
	hair_menu.set_accessory_color_preview(hair_accessory_color)

func set_skin_color(color : Color) -> void:
	current_skin_color = color

func set_eye_color(color : Color) -> void:
	current_eye_color = color
	
func set_hair_color(color : Color) -> void:
	current_hair_color = color

# BODY
func _on_body_type_requested(body_type: int) -> void:
	body_type_requested.emit(body_type)

func _on_skin_color_requested() -> void:
	_open_color_editor(
		ColorTarget.SKIN,
		Section.BODY,
		"Cor da pele",
		ColorPalettes.SKIN_TONES,
		current_skin_color
	)

func _on_eye_color_requested() -> void:
	_open_color_editor(
		ColorTarget.EYES,
		Section.BODY,
		"Cor dos olhos",
		ColorPalettes.EYES_TONES,
		current_eye_color
	)

func _on_body_confirmed() -> void:
	edit_confirmed.emit()
	
	close()
	
# HAIR
func _on_hair_requested(hair_id: int) -> void:
	hair_requested.emit(hair_id)
	
func _on_hair_color_requested() -> void:
	_open_color_editor(
		ColorTarget.HAIR,
		Section.HAIR,
		"Cor do cabelo",
		ColorPalettes.HAIR_TONES,
		current_hair_color
	)

func _on_hair_accessory_color_requested() -> void:
	_open_color_editor(
		ColorTarget.HAIR_ACCESSORY,
		Section.HAIR,
		"Cor do acessório",
		ColorPalettes.ACCESSORY_TONES,
		current_hair_accessory_color
	)
	
func _on_hair_confirmed() -> void:
	edit_confirmed.emit()
	
	close()

# OUTFIT
func set_outfit_body_type(body_type: int) -> void:
	outfit_menu.set_body_type(body_type)
	
func _on_outfit_requested(outfit_id: int) -> void:
	outfit_requested.emit(outfit_id)
	
func _on_outfit_confirmed() -> void:
	edit_confirmed.emit()
	
	close()

func _on_color_selected(color: Color) -> void:
	match current_color_target:
		ColorTarget.SKIN:
			current_skin_color = color
			skin_color_selected.emit(color)
		
		ColorTarget.EYES:
			current_eye_color = color
			eye_color_selected.emit(color)
			
		ColorTarget.HAIR:
			current_hair_color = color
			
			hair_menu.set_hair_color_preview(color)
			hair_color_selected.emit(color)
		
		ColorTarget.HAIR_ACCESSORY:
			current_hair_accessory_color = color
			
			hair_menu.set_accessory_color_preview(color)
			hair_accessory_color_selected.emit(color)
			
		_:
			pass
			
func _on_color_confirmed() -> void:
	edit_confirmed.emit()
	
	_return_from_color_menu()

func _open_color_editor(
	target: ColorTarget,
	parent_section: Section,
	title: String,
	colors: Dictionary,
	current_color: Color
) -> void:
	edit_started.emit()
	
	current_color_target = target
	color_parent_section = parent_section
	current_section = Section.COLOR
	
	hide_all_sections()
	
	color_menu.open_color_menu(
		title,
		colors,
		current_color
	)
	
# CUSTOM COLOR
func _on_custom_color_requested() -> void:
	edit_started.emit()
	
	current_section = Section.CUSTOM_COLOR
	
	hide_all_sections()
	
	var title: String
	var current_color: Color
	
	match current_color_target:
		ColorTarget.SKIN:
			title = "Cor personalizada do pele"
			current_color = current_skin_color
		
		ColorTarget.EYES:
			title = "Cor personalizada dos olhos"
			current_color = current_eye_color
			
		ColorTarget.HAIR:
			title = "Cor personalizada do cabelo"
			current_color = current_hair_color
		
		ColorTarget.HAIR_ACCESSORY:
			title = "Cor do acessório"
			current_color = current_hair_accessory_color
		_:
			return
	
	custom_color_menu.open_custom_color_menu(
		title,
		current_color
	)

func _on_custom_color_selected(color: Color) -> void:
	color_menu.set_custom_color_preview(color)
	_on_color_selected(color)

func _on_custom_color_confirmed() -> void:
	edit_confirmed.emit()
	
	current_section = Section.COLOR
	
	hide_all_sections()
	
	color_menu.show()
	
func _return_from_color_menu() -> void:
	var parent: Section = color_parent_section
	
	current_color_target = ColorTarget.NONE
	color_parent_section = Section.NONE
	
	match parent:
		Section.BODY:
			open_body()
		
		Section.HAIR:
			open_hair()
		
		_:
			close()
			
func request_back() -> bool:
	match current_section:
		Section.COLOR:
			edit_cancelled.emit()
			_return_from_color_menu()
			return true
		
		Section.CUSTOM_COLOR:
			edit_cancelled.emit()
			_return_from_custom_color_menu()
			return true
			
		Section.BODY, Section.HAIR, Section.OUTFIT:
			edit_cancelled.emit()
			close()
			return true
			
		_:
			return false
			
func _return_from_custom_color_menu() -> void:
	hide_all_sections()
	
	current_section = Section.COLOR
	
	color_menu.show()
	
func set_hair_accessory_available(has_accessory: bool) -> void:
	hair_menu.set_accessory_available(has_accessory)
