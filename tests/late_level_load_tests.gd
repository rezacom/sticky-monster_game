extends Node

var levels_to_check: Array[int] = [1, 40, 80, 120, 160, 200]


func _ready() -> void:
	var root := Control.new()
	add_child(root)
	SceneManager.setup(root)
	for level_id in levels_to_check:
		SceneManager.change_scene("res://scenes/gameplay/Gameplay.tscn", {"level_id": level_id}, false)
		await get_tree().process_frame
		var gameplay: Node = SceneManager.current_scene
		if gameplay == null:
			push_error("Gameplay did not load for level %d." % level_id)
			get_tree().quit(1)
			return
		if gameplay.level_id != level_id:
			push_error("Wrong level loaded: %d." % level_id)
			get_tree().quit(1)
			return
	print("Late level load tests passed.")
	get_tree().quit(0)
