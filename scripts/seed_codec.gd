class_name SeedCodec
extends RefCounted

const MAX_SEED := 2147483647


static func parse_seed(raw_text: String) -> Dictionary:
	var cleaned := raw_text.strip_edges().replace(" ", "")
	if cleaned.is_empty():
		return {"valid": false, "value": 0, "message": "ENTER A SEED"}
	if not cleaned.is_valid_int():
		return {"valid": false, "value": 0, "message": "USE NUMBERS ONLY"}
	var parsed := int(cleaned)
	if parsed <= 0 or parsed > MAX_SEED:
		return {"valid": false, "value": 0, "message": "SEED MUST BE 1–%d" % MAX_SEED}
	return {"valid": true, "value": parsed, "message": "SEED READY"}


static func format_seed(seed_value: int) -> String:
	return str(clampi(seed_value, 1, MAX_SEED))
