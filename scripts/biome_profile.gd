class_name BiomeProfile
extends RefCounted

var id: StringName
var display_name: String
var terrain_palette: Dictionary
var background_palette: Dictionary
var decoration_identifiers: PackedStringArray
var hazard_weights: Dictionary
var generator_difficulty: Dictionary
var ambience: StringName


func _init(
	profile_id: StringName,
	profile_display_name: String,
	profile_terrain_palette: Dictionary,
	profile_background_palette: Dictionary,
	profile_decoration_identifiers: PackedStringArray,
	profile_hazard_weights: Dictionary,
	profile_generator_difficulty: Dictionary,
	profile_ambience: StringName
) -> void:
	id = profile_id
	display_name = profile_display_name
	terrain_palette = profile_terrain_palette.duplicate(true)
	background_palette = profile_background_palette.duplicate(true)
	decoration_identifiers = profile_decoration_identifiers.duplicate()
	hazard_weights = profile_hazard_weights.duplicate(true)
	generator_difficulty = profile_generator_difficulty.duplicate(true)
	ambience = profile_ambience
