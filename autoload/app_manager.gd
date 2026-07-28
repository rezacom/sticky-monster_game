extends Node

signal result_ready(result: Dictionary)

var current_level_id := 1
var selected_world_id := 1
var last_result: Dictionary = {}


func continue_game() -> void:
	start_level(SaveManager.get_next_unfinished_level())


func start_level(level_id: int) -> void:
	current_level_id = clampi(level_id, 1, GameData.get_level_count())
	SaveManager.record_level_start(current_level_id)
	SceneManager.change_scene("res://scenes/gameplay/Gameplay.tscn", {"level_id": current_level_id})


func complete_current_level(stars: int, launches_used: int, collected_coin_indices: Array) -> void:
	var level_data: Dictionary = GameData.get_level(current_level_id)
	var reward: Dictionary = SaveManager.complete_level(level_data, stars, launches_used, collected_coin_indices)
	last_result = {
		"level_id": current_level_id,
		"success": true,
		"stars": stars,
		"launches": launches_used,
		"coins_collected": collected_coin_indices.size(),
		"xp": int(reward.get("xp", 0)),
		"coin_reward": int(reward.get("coins", 0)),
		"new_record": bool(reward.get("new_record", false))
	}
	emit_signal("result_ready", last_result)
	SceneManager.change_scene("res://scenes/results/Results.tscn", last_result)


func fail_current_level(reason: String) -> void:
	SaveManager.record_death(current_level_id)
	last_result = {
		"level_id": current_level_id,
		"success": false,
		"reason": reason,
		"stars": 0,
		"launches": 0,
		"coins_collected": 0,
		"xp": 0,
		"coin_reward": 0,
		"new_record": false
	}
	SceneManager.change_scene("res://scenes/results/Results.tscn", last_result)


func open_level_select(world_id: int) -> void:
	selected_world_id = clampi(world_id, 1, 10)
	SceneManager.change_scene("res://scenes/level_select/LevelSelect.tscn", {"world_id": selected_world_id})
