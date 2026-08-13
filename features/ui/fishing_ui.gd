class_name FishingUI
extends CanvasLayer

@onready var bite_label: Label = $BiteLabel
@onready var fight_panel: Panel = $FightPanel
@onready var progress_bar: ProgressBar = $FightPanel/ProgressBar
@onready var tension_bar: ProgressBar = $FightPanel/TensionBar
@onready var power_panel: Panel = $PowerPanel
@onready var power_bar: ProgressBar = $PowerPanel/PowerBar

@onready var message_timer: Timer = $MessageTimer

func _ready() -> void:
	bite_label.hide()
	power_panel.hide()
	fight_panel.hide()
	
	message_timer.timeout.connect(hide_result_message)
	
func setup(player_fishing: PlayerFishing) -> void:
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

func show_power_bar() -> void:
	power_bar.value = 0.0
	power_panel.show()

func update_power_bar(power: float) -> void:
	power_bar.value = power * 100.0

func fishing_power_bar(power: float) -> void:
	power_bar.value = power * 100.0
	power_panel.hide()
	
func show_bite_indicator() -> void:
	message_timer.stop()
	
	bite_label.text = "PUXOU!!!"
	bite_label.show()
	
func hide_bite_indicator() -> void:
	bite_label.hide()

func show_fighting_ui() -> void:
	power_panel.hide()
	bite_label.hide()
	
	progress_bar.value = 0.0
	tension_bar.value = 0.0
	
	fight_panel.show()
	
func update_fighting_ui(progress: float, tension: float) -> void:
	progress_bar.value = progress * 100.0
	tension_bar.value = tension * 100.0
	
func show_capture_message() -> void:
	power_panel.hide()
	fight_panel.hide()
	
	bite_label.text = "EXEMPLAR CAPTURADO!"
	bite_label.show()
	
	message_timer.start()
	
func show_escape_message() -> void:
	power_panel.hide()
	fight_panel.hide()
	
	bite_label.text = "PUTZ, ESCAPOU!"
	bite_label.show()
	
	message_timer.start()
	
func hide_result_message() -> void:
	bite_label.hide()

func hide_fishing_ui() -> void:
	power_panel.hide()
	fight_panel.hide()
	bite_label.hide()
	
