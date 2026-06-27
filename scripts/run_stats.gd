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
var manual_resets := 0
var total_run_time := 0.0


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
	manual_resets = 0
	total_run_time = 0.0


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
	water_resets += 1


func record_manual_reset() -> void:
	manual_resets += 1


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
