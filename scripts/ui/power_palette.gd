class_name PowerPalette
extends RefCounted

const LOW := Color("edbf45")
const HIGH := Color("ed596f")

static func color_at(power: float) -> Color:
	return LOW.lerp(HIGH, clampf(power, 0.0, 1.0))
