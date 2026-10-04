class_name VsMatchState
extends RefCounted
## Two private runs and one frozen course per hole. Never generates on turn swap.
enum Turn { PLAYER, OPPONENT, RESULTS }
var player: RunState
var opponent := RunState.new()
var profile: AIDifficultyProfile
var turn: Turn = Turn.PLAYER
var course_generation_count := 0
var hole_results: Array[Dictionary] = []
var shared_configuration: Dictionary = {}
var _courses: Dictionary = {}


func _init(player_state: RunState, opponent_id: StringName) -> void:
	player = player_state
	profile = AIDifficultyProfile.get_profile(opponent_id)
	opponent.difficulty_profile = player.difficulty_profile
	opponent.reset(player.run_seed)
	for index in 18:
		opponent.levels.append({"pending": true})


func prepare_course(index: int) -> Dictionary:
	if _courses.has(index):
		return course_definition(index)
	shared_configuration = MatchCourseRules.resolve(player, opponent)
	var options := player.difficulty_profile.generation_options()
	options.merge(shared_configuration, true)
	options["modifier_seed"] = ("vs-course/v1/%d/%d/%d/%s/%s" % [player.run_seed, index,
		shared_configuration.added_hazard_count, shared_configuration.preferred_hazard_type,
		str(shared_configuration.cup_radius_scale)]).hash()
	var definition := HoleGenerator.generate_hole(BiomeDatabase.get_profiles()[index / 3], player.run_seed,
		index / 3, index % 3, HoleGenerator.MAX_GENERATION_ATTEMPTS, options)
	definition["cup_radius"] = float(definition.get("cup_radius", 28.0)) * float(shared_configuration.cup_radius_scale)
	definition["match_course_modifiers"] = shared_configuration.duplicate(true)
	if not LevelValidator.validate_level(definition, index):
		return {}
	_courses[index] = definition.duplicate(true)
	course_generation_count += 1
	player.levels[index] = definition.duplicate(true)
	opponent.levels[index] = definition.duplicate(true)
	turn = Turn.PLAYER
	return definition.duplicate(true)


func course_definition(index: int) -> Dictionary:
	return Dictionary(_courses.get(index, {})).duplicate(true)


func finish_hole() -> Dictionary:
	if turn != Turn.OPPONENT or hole_results.size() > player.level_index:
		return {}
	var result := {"hole": player.level_index + 1, "par": int(course_definition(player.level_index).par),
		"player_strokes": player.strokes, "opponent_strokes": opponent.strokes,
		"player_time": player.level_elapsed, "opponent_time": opponent.level_elapsed,
		"player_failed": player.last_hole_forced, "opponent_failed": opponent.last_hole_forced,
		"winner": compare_scores(player.strokes, opponent.strokes, player.level_elapsed, opponent.level_elapsed)}
	hole_results.append(result)
	turn = Turn.RESULTS
	return result.duplicate(true)


func summary() -> Dictionary:
	var wins := 0
	var losses := 0
	var par := 0
	for hole in hole_results:
		wins += int(hole.winner == -1)
		losses += int(hole.winner == 1)
		par += int(hole.par)
	return {"player_strokes": player.total_strokes, "opponent_strokes": opponent.total_strokes,
		"player_time": player.stats.total_run_time, "opponent_time": opponent.stats.total_run_time,
		"par": par, "wins": wins, "losses": losses, "ties": hole_results.size() - wins - losses,
		"winner": compare_scores(player.total_strokes, opponent.total_strokes,
			player.stats.total_run_time, opponent.stats.total_run_time)}


static func compare_scores(first: int, second: int, first_time: float, second_time: float) -> int:
	if first != second:
		return -1 if first < second else 1
	# Compare displayed tenths, not invisible sub-frame differences.
	return signi(roundi(first_time * 10.0) - roundi(second_time * 10.0))
