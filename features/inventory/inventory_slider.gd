extends VSlider

@export var scroll_container: ScrollContainer

var _scroll_bar: VScrollBar
var _syncing: bool = false

func _ready() -> void:
	if scroll_container == null:
		push_error("InventorySlider: atribua o ScrollContainer.")
		return
		
	min_value = 0.0
	step = 1.0
	
	_scroll_bar = scroll_container.get_v_scroll_bar()
	
	value_changed.connect(_on_slider_value_changed)
	_scroll_bar.value_changed.connect(_on_scroll_value_changed)
	_scroll_bar.changed.connect(_sync_from_scroll)
	
	_sync_from_scroll.call_deferred()
	
func _sync_from_scroll() -> void:
	var limit := maxf(
		_scroll_bar.max_value - _scroll_bar.page,
		0.0
	)
	
	_syncing = true
	
	max_value = maxf(limit, 1.0)
	editable = limit > 0.0
	set_value_no_signal(max_value - _scroll_bar.value)
	
	_syncing = false
	
func _on_slider_value_changed(new_value: float) -> void:
	if _syncing:
		return
		
	scroll_container.scroll_vertical = roundi(max_value - new_value)

func _on_scroll_value_changed(_new_value: float) -> void:
	_sync_from_scroll()
	
	
	
	
	
	
	
	
	
	
	
