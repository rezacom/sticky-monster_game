extends Node

signal save_changed

const SAVE_VERSION := 3
const SAVE_PATH := "user://sticky_monster_save.json"

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = _default_save()
		save_game()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		data = _default_save()
		save_game()
		return

	var json: JSON = JSON.new()
	var parse_error: int = json.parse(file.get_as_text())
	if parse_error != OK:
		data = _default_save()
		save_game()
		return

	var parsed: Variant = json.data
	if not (parsed is Dictionary):
		data = _default_save()
		save_game()
		return

	var old_version: int = int(parsed.get("version", 0))
	data = _migrate(parsed)
	_sanitize()
	if old_version != SAVE_VERSION:
		save_game()


func save_game() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save file.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	emit_signal("save_changed")


func reset_progress() -> void:
	data = _default_save()
	save_game()


func record_level_start(level_id: int) -> void:
	data["last_played_level"] = level_id
	var record: Dictionary = get_level_record(level_id)
	record["attempts"] = int(record.get("attempts", 0)) + 1
	_set_level_record(level_id, record)
	save_game()


func record_death(level_id: int) -> void:
	var record: Dictionary = get_level_record(level_id)
	record["deaths"] = int(record.get("deaths", 0)) + 1
	data["total_deaths"] = int(data.get("total_deaths", 0)) + 1
	_set_level_record(level_id, record)
	save_game()


func complete_level(level_data: Dictionary, stars: int, launches_used: int, collected_coin_indices: Array) -> Dictionary:
	var level_id: int = int(level_data.get("id", 1))
	var old_record: Dictionary = get_level_record(level_id)
	var was_completed: bool = bool(old_record.get("completed", false))
	var previous_stars: int = int(old_record.get("stars", 0))
	var old_coins: Array = old_record.get("coins", [])
	var new_coin_count: int = 0

	for coin_index in collected_coin_indices:
		if not old_coins.has(int(coin_index)):
			old_coins.append(int(coin_index))
			new_coin_count += 1

	var best_launches: int = int(old_record.get("best_launches", 0))
	if best_launches <= 0 or launches_used < best_launches:
		best_launches = launches_used

	old_record["completed"] = true
	old_record["stars"] = max(previous_stars, stars)
	old_record["best_launches"] = best_launches
	old_record["coins"] = old_coins
	_set_level_record(level_id, old_record)

	if stars > 0:
		data["last_unlocked_level"] = max(int(data.get("last_unlocked_level", 1)), min(level_id + 1, GameData.get_level_count()))

	var xp_delta: int = 0
	if not was_completed:
		xp_delta += int(level_data.get("xp_reward", 35))
	xp_delta += max(0, stars - previous_stars) * int(GameData.balance.get("xp", {}).get("per_star", 18))
	xp_delta += new_coin_count * int(GameData.balance.get("xp", {}).get("per_coin", 4))

	var coin_delta: int = new_coin_count + (int(level_data.get("coin_reward", 0)) if not was_completed else 0)
	data["total_coins"] = int(data.get("total_coins", 0)) + coin_delta
	add_xp(xp_delta)
	refresh_skin_unlocks()
	save_game()

	return {
		"new_record": launches_used == best_launches,
		"xp": xp_delta,
		"coins": coin_delta,
		"stars": stars
	}


func add_xp(amount: int) -> void:
	var max_level: int = int(GameData.balance.get("xp", {}).get("max_level", 50))
	data["xp"] = int(data.get("xp", 0)) + max(0, amount)
	while int(data.get("player_level", 1)) < max_level:
		var required: int = GameData.xp_required_for_level(int(data.get("player_level", 1)))
		if int(data.get("xp", 0)) < required:
			break
		data["xp"] = int(data.get("xp", 0)) - required
		data["player_level"] = int(data.get("player_level", 1)) + 1
		data["total_coins"] = int(data.get("total_coins", 0)) + int(GameData.balance.get("rewards", {}).get("level_up_coins", 25))


func buy_skin(skin_id: String) -> bool:
	var skin: Dictionary = GameData.get_skin(skin_id)
	if skin.is_empty() or is_skin_unlocked(skin_id):
		return false
	var price: int = int(skin.get("price", 0))
	if String(skin.get("unlock", "")) != "coins" or int(data.get("total_coins", 0)) < price:
		return false
	data["total_coins"] = int(data.get("total_coins", 0)) - price
	data["unlocked_skins"].append(skin_id)
	data["selected_skin"] = skin_id
	save_game()
	return true


func select_skin(skin_id: String) -> bool:
	if not is_skin_unlocked(skin_id):
		return false
	data["selected_skin"] = skin_id
	save_game()
	return true


func refresh_skin_unlocks() -> void:
	for skin in GameData.skins:
		var skin_id: String = String(skin.get("id", ""))
		if is_skin_unlocked(skin_id):
			continue
		var unlock: String = String(skin.get("unlock", ""))
		var should_unlock: bool = false
		if unlock == "default":
			should_unlock = true
		elif unlock == "level":
			should_unlock = int(data.get("player_level", 1)) >= int(skin.get("level", 1))
		elif unlock == "stars":
			should_unlock = get_total_stars() >= int(skin.get("stars", 0))
		elif unlock == "world":
			should_unlock = is_world_completed(int(skin.get("world", 0)))
		if should_unlock:
			data["unlocked_skins"].append(skin_id)


func is_skin_unlocked(skin_id: String) -> bool:
	return data.get("unlocked_skins", []).has(skin_id)


func is_level_unlocked(level_id: int) -> bool:
	return level_id <= int(data.get("last_unlocked_level", 1))


func is_world_unlocked(world_id: int) -> bool:
	if world_id == 1:
		return true
	var levels: Array = GameData.get_levels_for_world(world_id)
	if levels.is_empty():
		return false
	return is_level_unlocked(int(levels[0].get("id", 1)))


func is_world_completed(world_id: int) -> bool:
	for level_data in GameData.get_levels_for_world(world_id):
		if int(get_level_record(int(level_data.get("id", 0))).get("stars", 0)) <= 0:
			return false
	return true


func get_level_record(level_id: int) -> Dictionary:
	var key: String = str(level_id)
	var records: Dictionary = data.get("levels", {})
	if not records.has(key):
		records[key] = _default_level_record()
		data["levels"] = records
	return records[key]


func get_world_stats(world_id: int) -> Dictionary:
	var completed: int = 0
	var stars: int = 0
	var coins: int = 0
	var total_coins: int = 0
	for level_data in GameData.get_levels_for_world(world_id):
		var record: Dictionary = get_level_record(int(level_data.get("id", 0)))
		if int(record.get("stars", 0)) > 0:
			completed += 1
		stars += int(record.get("stars", 0))
		coins += record.get("coins", []).size()
		total_coins += level_data.get("coins", []).size()
	return {"completed": completed, "stars": stars, "coins": coins, "total_coins": total_coins}


func get_total_stars() -> int:
	var total: int = 0
	for level_id in range(1, GameData.get_level_count() + 1):
		total += int(get_level_record(level_id).get("stars", 0))
	return total


func get_total_collected_level_coins() -> int:
	var total: int = 0
	for level_id in range(1, GameData.get_level_count() + 1):
		total += get_level_record(level_id).get("coins", []).size()
	return total


func get_progress_percent() -> float:
	var completed: int = 0
	for level_id in range(1, GameData.get_level_count() + 1):
		if int(get_level_record(level_id).get("stars", 0)) > 0:
			completed += 1
	return 100.0 * float(completed) / float(max(1, GameData.get_level_count()))


func get_next_unfinished_level() -> int:
	for level_id in range(1, int(data.get("last_unlocked_level", 1)) + 1):
		if int(get_level_record(level_id).get("stars", 0)) <= 0:
			return level_id
	return int(data.get("last_unlocked_level", 1))


func update_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	save_game()


func get_setting(key: String, fallback: Variant = null) -> Variant:
	return data.get("settings", {}).get(key, fallback)


func _set_level_record(level_id: int, record: Dictionary) -> void:
	var records: Dictionary = data.get("levels", {})
	records[str(level_id)] = record
	data["levels"] = records


func _default_save() -> Dictionary:
	var level_records: Dictionary = {}
	var level_count: int = max(200, GameData.get_level_count())
	for level_id in range(1, level_count + 1):
		level_records[str(level_id)] = _default_level_record()
	return {
		"version": SAVE_VERSION,
		"last_unlocked_level": 1,
		"last_played_level": 1,
		"player_level": 1,
		"xp": 0,
		"total_coins": 0,
		"total_deaths": 0,
		"unlocked_skins": ["green"],
		"selected_skin": "green",
		"levels": level_records,
		"settings": {
			"music_enabled": true,
			"music_volume": 0.75,
			"sfx_enabled": true,
			"sfx_volume": 0.85,
			"vibration_enabled": true,
			"quality": "Medium",
			"language": "fa",
			"aim_guide_enabled": true,
			"reduced_motion": false
		},
		"total_play_time": 0.0
	}


func _default_level_record() -> Dictionary:
	return {"stars": 0, "best_launches": 0, "coins": [], "completed": false, "attempts": 0, "deaths": 0}


func _migrate(old_data: Dictionary) -> Dictionary:
	if int(old_data.get("version", 0)) > SAVE_VERSION:
		return _default_save()
	var migrated: Dictionary = _default_save()
	for key in old_data.keys():
		migrated[key] = old_data[key]
	if int(old_data.get("version", 0)) < 2:
		var settings: Dictionary = migrated.get("settings", {})
		if String(settings.get("language", "en")) == "en":
			settings["language"] = "fa"
			migrated["settings"] = settings
	migrated["version"] = SAVE_VERSION
	return migrated


func _sanitize() -> void:
	var level_count: int = max(1, GameData.get_level_count())
	data["last_unlocked_level"] = clampi(int(data.get("last_unlocked_level", 1)), 1, level_count)
	data["last_played_level"] = clampi(int(data.get("last_played_level", 1)), 1, level_count)
	data["player_level"] = clampi(int(data.get("player_level", 1)), 1, int(GameData.balance.get("xp", {}).get("max_level", 50)))
	data["xp"] = max(0, int(data.get("xp", 0)))
	data["total_coins"] = max(0, int(data.get("total_coins", 0)))
	if not data.has("levels") or not (data["levels"] is Dictionary):
		data["levels"] = {}
	for level_id in range(1, level_count + 1):
		get_level_record(level_id)
	if not data.has("unlocked_skins") or not (data["unlocked_skins"] is Array):
		data["unlocked_skins"] = ["green"]
	if not data["unlocked_skins"].has("green"):
		data["unlocked_skins"].append("green")
	if not data.has("settings") or not (data["settings"] is Dictionary):
		data["settings"] = _default_save()["settings"]
