extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_fit_to_viewport()
	resized.connect(_fit_to_viewport)
	SceneManager.setup($ScreenRoot)
	call_deferred("_open_first_scene")


func _input(event: InputEvent) -> void:
	if _route_pointer_release(event):
		return
	if event.is_action_pressed("ui_cancel"):
		SceneManager.go_back()


func _gui_input(event: InputEvent) -> void:
	_route_pointer_release(event)


func _open_first_scene() -> void:
	SceneManager.change_scene("res://scenes/splash/Splash.tscn", {}, false)


func _fit_to_viewport() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var screen_root: Control = $ScreenRoot as Control
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_root.mouse_filter = Control.MOUSE_FILTER_PASS


func _route_pointer_release(event: InputEvent) -> bool:
	var position := Vector2.ZERO
	var released := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		position = event.position
		released = true
	elif event is InputEventScreenTouch and not event.pressed:
		position = event.position
		released = true
	if not released:
		return false
	if SceneManager.current_scene != null and SceneManager.current_scene.has_method("handle_pointer_release"):
		var viewport: Viewport = get_viewport()
		var handled: bool = bool(SceneManager.current_scene.call("handle_pointer_release", position))
		if handled and viewport != null:
			viewport.set_input_as_handled()
		return handled
	return false
