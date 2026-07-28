extends Node

var failures: Array[String] = []
var original_save: Dictionary = {}


func _ready() -> void:
	_run()


func _run() -> void:
	original_save = SaveManager.data.duplicate(true)
	SaveManager.data = SaveManager._default_save()
	_run_tests()
	SaveManager.data = original_save
	SaveManager.save_game()
	if failures.is_empty():
		print("Logic tests passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _run_tests() -> void:
	_assert(GameData.get_level_count() == 200, "Expected exactly 200 levels.")
	_assert(GameData.worlds.size() == 10, "Expected exactly 10 worlds.")
	_assert(GameData.skins.size() >= 12, "Expected at least 12 skins.")

	var level: Dictionary = GameData.get_level(1)
	_assert(GameData.calculate_stars(level, int(level.get("ideal_launches", 2))) == 3, "Ideal launches should award 3 stars.")
	_assert(GameData.calculate_stars(level, int(level.get("ideal_launches", 2)) + 2) == 2, "Two extra launches should award 2 stars.")
	_assert(GameData.calculate_stars(level, int(level.get("ideal_launches", 2)) + 3) == 1, "More launches should award 1 star.")
	_assert(GameData.calculate_stars(level, 1, true) == 0, "Failed level should award 0 stars.")

	_assert(SaveManager.is_level_unlocked(1), "Level 1 should be unlocked by default.")
	_assert(not SaveManager.is_level_unlocked(2), "Level 2 should start locked.")
	SaveManager.complete_level(level, 2, 4, [0, 1])
	_assert(SaveManager.is_level_unlocked(2), "Completing level 1 should unlock level 2.")
	_assert(SaveManager.get_total_stars() == 2, "Total stars should update.")
	_assert(int(SaveManager.data.get("total_coins", 0)) > 0, "Coins should be awarded.")

	SaveManager.data["total_coins"] = 500
	_assert(SaveManager.buy_skin("blue"), "Coin skin should be purchasable.")
	_assert(SaveManager.select_skin("blue"), "Owned skin should be selectable.")
	_assert(String(SaveManager.data.get("selected_skin", "")) == "blue", "Selected skin should persist in save data.")

	SaveManager.add_xp(5000)
	_assert(int(SaveManager.data.get("player_level", 1)) > 1, "XP should increase player level.")
	_assert(SaveManager.get_progress_percent() > 0.0, "Progress percent should increase after completion.")
	_assert(SaveManager.is_world_unlocked(1), "World 1 should be unlocked.")
	_assert(not SaveManager.is_world_unlocked(3), "World 3 should remain locked early.")

	var migrated: Dictionary = SaveManager._migrate({"version": 0, "total_coins": 7})
	_assert(int(migrated.get("version", 0)) == SaveManager.SAVE_VERSION, "Migration should update save version.")
	_assert(int(migrated.get("total_coins", 0)) == 7, "Migration should preserve compatible values.")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
