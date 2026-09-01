class_name BiomeHazardProfiles
extends RefCounted

const STATIC_HAZARD_TYPES := [
	"sand",
	"water",
	"lava",
	"ice",
	"direction",
	"bounce_pad",
]
const MOVING_HAZARD_TYPES := [
	"pendulum",
	"falling_ice",
	"rotating_fire_rod",
]

const PROFILES := {
	&"meadow": {
		"reset_hazard": "water",
		"static_weights": {"water": 4.0, "sand": 2.0, "direction": 1.0, "bounce_pad": 1.0},
		"moving_sequence": ["", "", "pendulum"],
	},
	&"desert": {
		"reset_hazard": "water",
		"static_weights": {"sand": 5.0, "water": 1.0, "direction": 2.0, "bounce_pad": 1.5},
		"moving_sequence": ["", "pendulum", "pendulum"],
	},
	&"autumn": {
		"reset_hazard": "water",
		"static_weights": {"water": 2.5, "sand": 2.0, "direction": 2.0, "bounce_pad": 1.5},
		"moving_sequence": ["", "pendulum", "pendulum"],
	},
	&"snow": {
		"reset_hazard": "water",
		"static_weights": {"ice": 5.0, "water": 2.0, "sand": 1.0, "bounce_pad": 1.0},
		"moving_sequence": ["falling_ice", "falling_ice", "falling_ice"],
	},
	&"swamp": {
		"reset_hazard": "water",
		"static_weights": {"water": 5.0, "sand": 1.5, "direction": 1.5, "bounce_pad": 1.0},
		"moving_sequence": ["", "pendulum", "pendulum"],
	},
	&"volcanic": {
		"reset_hazard": "lava",
		"static_weights": {"lava": 5.0, "sand": 1.0, "direction": 1.0, "bounce_pad": 1.5},
		"moving_sequence": ["rotating_fire_rod", "rotating_fire_rod", "rotating_fire_rod"],
	},
}


static func profile_for(biome_id: StringName) -> Dictionary:
	var normalized_id := StringName(String(biome_id).to_lower())
	if PROFILES.has(normalized_id):
		return Dictionary(PROFILES[normalized_id]).duplicate(true)
	return Dictionary(PROFILES[&"meadow"]).duplicate(true)


static func reset_hazard_for(biome_id: StringName) -> String:
	return String(profile_for(biome_id).reset_hazard)


static func static_weights_for(biome_id: StringName) -> Dictionary:
	return Dictionary(profile_for(biome_id).static_weights).duplicate(true)


static func moving_hazard_for(biome_id: StringName, hole_index: int) -> String:
	var sequence: Array = profile_for(biome_id).moving_sequence
	if sequence.is_empty():
		return ""
	return String(sequence[clampi(hole_index, 0, sequence.size() - 1)])


static func required_static_types(biome_id: StringName, hole_index: int) -> Array[String]:
	var required: Array[String] = [reset_hazard_for(biome_id)]
	var normalized_id := String(biome_id).to_lower()
	if normalized_id == "snow":
		required.append("ice")
	if hole_index >= 1 and normalized_id in ["meadow", "desert", "autumn", "swamp", "volcanic"]:
		required.append("bounce_pad")
	return required
