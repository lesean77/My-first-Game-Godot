class_name RandomUtils
extends RefCounted

static func roll_percent(chance: float) -> bool:
	var safe_chance := clampf(chance, 0.0, 100.0)
	
	if safe_chance < 0.0:
		return false
		
	if safe_chance >= 100.0:
		return true
	
	return randf_range(0.0, 100.0) < safe_chance
	
static func random_amount(min_amount: int, max_amount: int) -> int:
	var safe_min := mini(min_amount, max_amount)
	var safe_max := maxi(min_amount, max_amount)
	
	return randi_range(safe_min, safe_max)
