class_name DifficultyDatabase
extends RefCounted

const DifficultyProfileScript := preload("res://scripts/difficulty_profile.gd")

const EASY := &"easy"
const NORMAL := &"normal"
const HARD := &"hard"
const DEFAULT_ID := NORMAL


static func get_profiles() -> Array[DifficultyProfile]:
	return [
		DifficultyProfileScript.new(EASY, "EASY", 4, 2, 1.0, 0.9, "NORMAL CURSES"),
		DifficultyProfileScript.new(NORMAL, "NORMAL", 5, 3, 1.25, 1.0, "STRONGER CURSES"),
		DifficultyProfileScript.new(HARD, "HARD", 6, 5, 1.6, 1.15, "BRUTAL CURSES"),
	]


static func get_profile(profile_id: StringName) -> DifficultyProfile:
	for profile in get_profiles():
		if profile.id == profile_id:
			return profile
	return get_profile(DEFAULT_ID) if profile_id != DEFAULT_ID else get_profiles()[1]


static func is_valid_id(profile_id: StringName) -> bool:
	return profile_id in [EASY, NORMAL, HARD]
