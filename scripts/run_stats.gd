class_name RunStats
extends RefCounted

var total_strokes := 0
var final_score_relative_to_par := 0
var cards_bought: Array[String] = []
var hazards_entered := {
	"sand": 0,
	"water": 0,
	"direction": 0
}
var water_resets := 0
var hazard_resets := {}
var manual_resets := 0
var total_run_time := 0.0
var hole_history: Array[Dictionary] = []


func reset() -> void:
	total_strokes = 0
	final_score_relative_to_par = 0
	cards_bought.clear()
	hazards_entered = {
		"sand": 0,
		"water": 0,
		"direction": 0
	}
	water_resets = 0
	hazard_resets.clear()
	manual_resets = 0
	total_run_time = 0.0
	hole_history.clear()


func update_time(delta: float) -> void:
	total_run_time += delta


func record_stroke() -> void:
	total_strokes += 1


func record_card_bought(card_name: String) -> void:
	cards_bought.append(card_name)


func record_hazard_entered(hazard_type: String) -> void:
	if not hazards_entered.has(hazard_type):
		hazards_entered[hazard_type] = 0
	hazards_entered[hazard_type] += 1


func record_water_reset() -> void:
	record_hazard_reset("water")


func record_hazard_reset(hazard_type: String) -> void:
	if not hazard_resets.has(hazard_type):
		hazard_resets[hazard_type] = 0
	hazard_resets[hazard_type] += 1
	if hazard_type == "water":
		water_resets += 1


func record_manual_reset() -> void:
	manual_resets += 1


func record_hole_result(entry: Dictionary) -> void:
	var hole_number := int(entry.get("hole_number", 0))
	if hole_number <= 0:
		return
	for history_index in range(hole_history.size()):
		if int(hole_history[history_index].get("hole_number", 0)) == hole_number:
			hole_history[history_index] = entry.duplicate(true)
			return
	hole_history.append(entry.duplicate(true))
	hole_history.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return int(first.get("hole_number", 0)) < int(second.get("hole_number", 0))
	)


func can_view_hole(hole_number: int, current_hole_number: int) -> bool:
	if hole_number < 1 or hole_number > current_hole_number:
		return false
	if hole_number == current_hole_number:
		return true
	return not get_hole_result(hole_number).is_empty()


func get_hole_result(hole_number: int) -> Dictionary:
	for entry in hole_history:
		if int(entry.get("hole_number", 0)) == hole_number:
			return entry.duplicate(true)
	return {}


func history_snapshot() -> Array[Dictionary]:
	return hole_history.duplicate(true)


func print_summary(total_par: int) -> void:
	final_score_relative_to_par = total_strokes - total_par
	print("\n=== A Stroke of Luck Run Summary ===")
	print("Total strokes: %d" % total_strokes)
	print("Total par: %d" % total_par)
	print("Score relative to par: %s" % _format_score_to_par(final_score_relative_to_par))
	print("Cards bought: %s" % _format_cards())
	print("Hazards entered: sand %d, water %d, direction %d" % [
		int(hazards_entered.get("sand", 0)),
		int(hazards_entered.get("water", 0)),
		int(hazards_entered.get("direction", 0))
	])
	print("Water resets: %d" % water_resets)
	print("Manual resets: %d" % manual_resets)
	print("Total run time: %s" % _format_time(total_run_time))
	print("====================================\n")


func _format_score_to_par(score_to_par: int) -> String:
	if score_to_par == 0:
		return "Even par"
	if score_to_par > 0:
		return "+%d" % score_to_par
	return "%d" % score_to_par


func _format_cards() -> String:
	if cards_bought.is_empty():
		return "None"
	return ", ".join(cards_bought)


func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := total_seconds / 60
	var remaining_seconds := total_seconds % 60
	return "%02d:%02d" % [minutes, remaining_seconds]
