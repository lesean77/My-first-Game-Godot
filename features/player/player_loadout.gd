const MIN_QUICK_SLOTS: int = 3
const MAX_QUICK_SLOTS: int = 6

signal quick_slots_changed

@export_range(MIN_QUICK_SLOTS, MAX_QUICK_SLOTS, 1)
var unlocked_quick_slots: int = MIN_QUICK_SLOTS

var quick_slots: Array[EquipmentData] = []


func _ready() -> void:
	initialize_quick_slots()


func initialize_quick_slots() -> void:
	unlocked_quick_slots = clampi(
		unlocked_quick_slots,
		MIN_QUICK_SLOTS,
		MAX_QUICK_SLOTS
	)

	quick_slots.resize(unlocked_quick_slots)

func unlock_quick_slot() -> bool:
	if unlocked_quick_slots >= MAX_QUICK_SLOTS:
		return false

	unlocked_quick_slots += 1
	quick_slots.resize(unlocked_quick_slots)

	quick_slots_changed.emit()
	return true

func set_unlocked_quick_slots(amount: int) -> void:
	var new_amount := clampi(
		amount,
		MIN_QUICK_SLOTS,
		MAX_QUICK_SLOTS
	)

	if new_amount == unlocked_quick_slots:
		return

	unlocked_quick_slots = new_amount
	quick_slots.resize(unlocked_quick_slots)

	quick_slots_changed.emit()
