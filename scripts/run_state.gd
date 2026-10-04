class_name RunState
extends RefCounted
## Scene-local mutable round data. Never an autoload or shared Resource.
## Main coordinates nodes; this object owns accounting, cards and lifecycle.

const STARTING_TOKENS := 2
const HOLES_PER_BIOME := 3
const STROKES_OVER_PAR := 4
enum Phase { MAIN_MENU, RUN_START, BIOME_INTRO, HOLE_PLAY, HOLE_RESULTS, SHOP, RUN_RESULTS, ENDING, PREPARE_HOLE, HOLE_RESOLVING }
const PHASE_NAMES := ["MAIN_MENU", "RUN_START", "BIOME_INTRO", "HOLE_PLAY", "HOLE_RESULTS", "SHOP", "RUN_RESULTS", "ENDING", "PREPARE_HOLE", "HOLE_RESOLVING"]
const NEXT_PHASES := {
	Phase.MAIN_MENU: [Phase.RUN_START, Phase.PREPARE_HOLE],
	Phase.RUN_START: [Phase.BIOME_INTRO, Phase.PREPARE_HOLE],
	Phase.BIOME_INTRO: [Phase.PREPARE_HOLE],
	Phase.PREPARE_HOLE: [Phase.HOLE_PLAY, Phase.RUN_RESULTS],
	Phase.HOLE_PLAY: [Phase.HOLE_RESOLVING, Phase.PREPARE_HOLE],
	Phase.HOLE_RESOLVING: [Phase.HOLE_RESULTS, Phase.SHOP, Phase.PREPARE_HOLE],
	Phase.HOLE_RESULTS: [Phase.PREPARE_HOLE, Phase.SHOP, Phase.RUN_RESULTS],
	Phase.SHOP: [Phase.BIOME_INTRO, Phase.PREPARE_HOLE],
	Phase.RUN_RESULTS: [Phase.ENDING],
	Phase.ENDING: [],
}

var phase: Phase = Phase.MAIN_MENU
var menu_paused := false
var level_index := 0
var biome_index: int:
	get: return level_index / HOLES_PER_BIOME
var hole_index: int:
	get: return level_index % HOLES_PER_BIOME
var overall_hole_number: int:
	get: return level_index + 1
var run_seed := 0
var tutorial_mode := false
var difficulty_profile: DifficultyProfile
var generation_fallback_count := 0
var last_hole_reward := 0
var last_hole_forced := false
var last_hole_rating: Dictionary = {}
var strokes := 0
var tokens := STARTING_TOKENS
var level_elapsed := 0.0
var stats := RunStats.new()
var total_strokes: int:
	get: return stats.total_strokes
	set(value): stats.total_strokes = value
var owned_cards: Array[String]:
	get: return stats.cards_bought
var owned_card_definitions: Array[CardDefinition] = []
var active_card_curses: Array[ActiveCardCurse] = []
var last_expired_curses: Array[String] = []
var levels: Array[Dictionary] = []
var normal_levels: Array[Dictionary] = []
var accepted_shot_id := 0
var _refundable_shot_id := -1
var _refundable_hole := -1

# Resolved cache, written together by refresh_effects. Physics consumes values;
# UI receives copied descriptions, never these mutable card/curse objects.
var impulse_modifier := 1.0
var drag_modifier := 1.0
var roll_damp_modifier := 1.0
var trajectory_dot_bonus := 0
var sand_damp_modifier := 1.0
var direction_push_modifier := 1.0
var reward_bonus := 0
var birdie_reward_bonus := 0
var terrain_mitigation_modifier := 0.0
var cup_radius_scale := 1.0
var active_hazard_count_modifier := 0
var active_hazard_type: StringName = &""


func reset(seed_value: int) -> void:
	phase = Phase.MAIN_MENU
	menu_paused = false
	run_seed = seed_value
	level_index = 0
	generation_fallback_count = 0
	last_hole_reward = 0
	last_hole_forced = false
	last_hole_rating = {}
	strokes = 0
	invalidate_shot_refund()
	tokens = STARTING_TOKENS
	level_elapsed = 0.0
	stats.reset()
	owned_card_definitions.clear()
	active_card_curses.clear()
	last_expired_curses.clear()
	levels = []
	normal_levels = []
	refresh_effects()


func transition_to(next_phase: Phase) -> bool:
	if next_phase == phase:
		return false
	if next_phase != Phase.MAIN_MENU and not NEXT_PHASES.get(phase, []).has(next_phase):
		return false
	phase = next_phase
	return true


func is_playing() -> bool:
	return phase == Phase.HOLE_PLAY and not menu_paused


func record_stroke() -> void:
	strokes += 1
	stats.record_stroke()


func record_accepted_shot() -> int:
	accepted_shot_id += 1
	_refundable_shot_id = accepted_shot_id
	_refundable_hole = level_index
	record_stroke()
	return accepted_shot_id


func invalidate_shot_refund() -> void:
	_refundable_shot_id = -1
	_refundable_hole = -1


func refund_out_of_bounds_shot(shot_id: int) -> bool:
	if phase != Phase.HOLE_PLAY or shot_id != _refundable_shot_id or _refundable_hole != level_index or strokes <= 0:
		return false
	invalidate_shot_refund()
	strokes -= 1
	stats.total_strokes = maxi(stats.total_strokes - 1, 0)
	return true


func remaining_shots(par: int) -> int:
	return maxi(par + STROKES_OVER_PAR - strokes, 0)


func update_time(delta: float) -> void:
	if is_playing():
		var elapsed := maxf(delta, 0.0)
		level_elapsed += elapsed
		stats.update_time(elapsed)


func add_card(card: CardDefinition) -> void:
	owned_card_definitions.append(card)
	active_card_curses.append(ActiveCardCurse.new(card))
	stats.record_card_bought(card.name)
	refresh_effects()


func advance_curses() -> void:
	last_expired_curses.clear()
	for index in range(active_card_curses.size() - 1, -1, -1):
		var curse := active_card_curses[index]
		if curse.advance_hole():
			last_expired_curses.append(curse.card.name)
			active_card_curses.remove_at(index)
	last_expired_curses.reverse()
	refresh_effects()


func refresh_effects() -> void:
	var multiplier := 1.0 if tutorial_mode or not difficulty_profile else difficulty_profile.curse_strength_multiplier
	var effects := CardEffectResolver.resolve(owned_card_definitions, active_card_curses, multiplier)
	impulse_modifier = 1.0 + effects.shot_power_delta
	drag_modifier = 1.0 + effects.power_control_delta
	roll_damp_modifier = 1.0 + effects.roll_damping_delta
	trajectory_dot_bonus = effects.trajectory_dot_delta
	terrain_mitigation_modifier = effects.terrain_mitigation_delta
	sand_damp_modifier = 1.0 - terrain_mitigation_modifier
	direction_push_modifier = 1.0 - effects.direction_mitigation_delta
	reward_bonus = effects.coin_reward_delta
	birdie_reward_bonus = effects.birdie_reward_delta
	active_hazard_count_modifier = effects.hazard_count_delta
	active_hazard_type = effects.hazard_type
	cup_radius_scale = 1.0 + effects.cup_radius_scale_delta


func reward_for_score(final_strokes: int, par: int) -> int:
	var score := final_strokes - par
	var reward := 3 if score <= -1 else (2 if score == 0 else (1 if score == 1 else 0))
	return reward + reward_bonus + (birdie_reward_bonus if score <= -1 else 0)


func snapshot() -> Dictionary:
	return {
		"seed": run_seed, "difficulty": difficulty_profile.id if difficulty_profile else &"normal",
		"phase": PHASE_NAMES[phase], "hole": overall_hole_number,
		"strokes": strokes, "total_strokes": total_strokes, "coins": tokens,
		"time": level_elapsed, "run_time": stats.total_run_time,
		"bonuses": owned_cards.duplicate(), "history": stats.history_snapshot(),
		"rating": last_hole_rating.duplicate(true),
	}
