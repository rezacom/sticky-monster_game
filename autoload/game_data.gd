extends Node

const LEVELS_PATH := "res://data/levels/levels.json"
const WORLDS_PATH := "res://data/worlds/worlds.json"
const SKINS_PATH := "res://data/skins/skins.json"
const BALANCE_PATH := "res://data/balance/gameplay.json"

var levels: Array = []
var worlds: Array = []
var skins: Array = []
var balance: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	levels = _load_json_array(LEVELS_PATH)
	worlds = _load_json_array(WORLDS_PATH)
	skins = _load_json_array(SKINS_PATH)
	balance = _load_json_dict(BALANCE_PATH)


func get_level(level_id: int) -> Dictionary:
	for level_data in levels:
		if int(level_data.get("id", 0)) == level_id:
			return level_data
	return {}


func get_world(world_id: int) -> Dictionary:
	for world_data in worlds:
		if int(world_data.get("id", 0)) == world_id:
			return world_data
	return {}


func get_skin(skin_id: String) -> Dictionary:
	for skin_data in skins:
		if String(skin_data.get("id", "")) == skin_id:
			return skin_data
	return skins[0] if skins.size() > 0 else {}


func get_levels_for_world(world_id: int) -> Array:
	var result: Array = []
	for level_data in levels:
		if int(level_data.get("world", 0)) == world_id:
			result.append(level_data)
	return result


func get_level_count() -> int:
	return levels.size()


func calculate_stars(level_data: Dictionary, launches_used: int, failed: bool = false) -> int:
	if failed:
		return 0
	var ideal: int = int(level_data.get("ideal_launches", 3))
	var two_star_extra: int = int(balance.get("stars", {}).get("two_star_extra_launches", 2))
	if launches_used <= ideal:
		return 3
	if launches_used <= ideal + two_star_extra:
		return 2
	return 1


func xp_required_for_level(player_level: int) -> int:
	var xp_data: Dictionary = balance.get("xp", {})
	var base: int = int(xp_data.get("base_required", 100))
	var growth: int = int(xp_data.get("growth_per_level", 34))
	return base + max(0, player_level - 1) * growth


func color_from_hex(hex: String, fallback: Color = Color.WHITE) -> Color:
	var clean: String = hex.strip_edges()
	if clean.begins_with("#"):
		clean = clean.substr(1)
	if clean.length() != 6:
		return fallback
	return Color.html("#" + clean)


func _load_json_array(path: String) -> Array:
	var data: Variant = _load_json(path)
	if data is Array:
		return data
	push_warning("Expected JSON array at %s." % path)
	return []


func _load_json_dict(path: String) -> Dictionary:
	var data: Variant = _load_json(path)
	if data is Dictionary:
		return data
	push_warning("Expected JSON dictionary at %s." % path)
	return {}


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Could not open data file: %s" % path)
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_warning("Could not parse JSON: %s" % path)
	return parsed
