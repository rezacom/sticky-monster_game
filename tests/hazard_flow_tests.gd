extends Node


func _ready() -> void:
	var root := Control.new()
	add_child(root)
	SceneManager.setup(root)
	AppManager.current_level_id = 31
	SceneManager.change_scene("res://scenes/gameplay/Gameplay.tscn", {"level_id": 31}, false)
	await get_tree().process_frame
	var gameplay: Node = SceneManager.current_scene
	if gameplay == null:
		push_error("Gameplay did not load.")
		get_tree().quit(1)
		return
	gameplay.call("_on_player_died")
	await get_tree().process_frame
	if SceneManager.current_path != "res://scenes/results/Results.tscn":
		push_error("Hazard death did not open results scene.")
		get_tree().quit(1)
		return
	print("Hazard flow tests passed.")
	get_tree().quit(0)
