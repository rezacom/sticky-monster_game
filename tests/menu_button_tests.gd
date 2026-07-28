extends Node


func _ready() -> void:
	var packed: PackedScene = load("res://scenes/app/AppRoot.tscn")
	var app: Control = packed.instantiate()
	get_tree().root.add_child.call_deferred(app)
	await get_tree().create_timer(1.2).timeout

	var menu: Node = SceneManager.current_scene
	if menu == null:
		push_error("Main menu did not load.")
		get_tree().quit(1)
		return

	var buttons := _find_buttons(menu)
	if buttons.size() < 5:
		push_error("Expected menu buttons to be present.")
		get_tree().quit(1)
		return

	for button in buttons:
		if button.mouse_filter != Control.MOUSE_FILTER_STOP:
			push_error("Menu button is not clickable: %s" % button.text)
			get_tree().quit(1)
			return

	var worlds_button := buttons[1]
	var center: Vector2 = worlds_button.get_global_rect().get_center()
	print("App size=%s ScreenRoot size=%s Menu size=%s Button rect=%s" % [
		app.size,
		app.get_node("ScreenRoot").size,
		menu.size,
		worlds_button.get_global_rect()
	])
	_click(center)
	await get_tree().create_timer(0.2).timeout
	if SceneManager.current_path != "res://scenes/world_select/WorldSelect.tscn":
		push_error("World select button did not react to mouse click.")
		get_tree().quit(1)
		return

	print("Menu button tests passed.")
	get_tree().quit(0)


func _find_buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	if node is Button:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_buttons(child))
	return result


func _click(position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	get_viewport().push_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	get_viewport().push_input(release)
