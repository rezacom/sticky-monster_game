extends Node

var screen_root: Node = null
var current_scene: Node = null
var current_path := ""
var current_args: Dictionary = {}
var history: Array = []
var changing := false


func setup(root: Node) -> void:
	screen_root = root


func change_scene(path: String, args: Dictionary = {}, add_history: bool = true) -> void:
	if changing:
		return
	if path == current_path and args == current_args:
		return
	changing = true
	if add_history and current_path != "":
		history.append({"path": current_path, "args": current_args})

	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("Could not load scene: %s" % path)
		changing = false
		return

	if screen_root == null:
		current_path = path
		current_args = args.duplicate(true)
		var error: int = get_tree().change_scene_to_packed(packed)
		if error != OK:
			push_error("Could not change scene directly: %s" % path)
		changing = false
		return

	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null

	current_scene = packed.instantiate()
	_prepare_control_scene(current_scene)
	screen_root.add_child(current_scene)
	current_path = path
	current_args = args.duplicate(true)
	if current_scene.has_method("setup"):
		current_scene.call("setup", args)
	changing = false


func _prepare_control_scene(scene: Node) -> void:
	if not (scene is Control):
		return
	var control: Control = scene as Control
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_PASS


func go_back() -> void:
	if current_path == "res://scenes/gameplay/Gameplay.tscn" and current_scene != null and current_scene.has_method("toggle_pause"):
		current_scene.call("toggle_pause")
		return
	if history.is_empty():
		if current_path == "res://scenes/main_menu/MainMenu.tscn":
			get_tree().quit()
		else:
			change_scene("res://scenes/main_menu/MainMenu.tscn", {}, false)
		return
	var previous: Dictionary = history.pop_back()
	change_scene(String(previous.get("path", "res://scenes/main_menu/MainMenu.tscn")), previous.get("args", {}), false)
