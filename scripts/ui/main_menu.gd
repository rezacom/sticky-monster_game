extends Control

var monster_time := 0.0
var action_buttons: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		handle_pointer_release(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		handle_pointer_release(event.position)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		handle_pointer_release(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		handle_pointer_release(event.position)


func _process(delta: float) -> void:
	monster_time += delta
	queue_redraw()


func _build() -> void:
	_clear()
	action_buttons.clear()
	_add_background()

	var title := _label(LocalizationManager.tr_key("game_title"), Vector2(54, 48), Vector2(972, 100), 70, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.34))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var map_title := _label("🛡️ قرارگاه پرتاب", Vector2(74, 170), Vector2(460, 60), 38, HORIZONTAL_ALIGNMENT_LEFT)
	map_title.add_theme_color_override("font_color", Color(0.93, 1.0, 0.86))
	map_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_title)

	var stats_panel := PanelContainer.new()
	stats_panel.position = Vector2(58, 500)
	stats_panel.size = Vector2(964, 250)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_panel)

	var stats := _label(_stats_text(), Vector2(22, 18), Vector2(900, 188), 36, HORIZONTAL_ALIGNMENT_CENTER)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_panel.add_child(stats)

	var xp_bar := ProgressBar.new()
	xp_bar.position = Vector2(112, 770)
	xp_bar.size = Vector2(856, 48)
	xp_bar.max_value = GameData.xp_required_for_level(int(SaveManager.data.get("player_level", 1)))
	xp_bar.value = int(SaveManager.data.get("xp", 0))
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_bar)

	var command := _label("🎯 انتخاب عملیات", Vector2(80, 850), Vector2(520, 56), 38, HORIZONTAL_ALIGNMENT_LEFT)
	command.add_theme_color_override("font_color", Color(1.0, 0.92, 0.42))
	command.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(command)

	_add_button("▶  " + LocalizationManager.tr_key("continue"), Vector2(82, 920), Vector2(916, 112), Callable(AppManager, "continue_game"), 42)
	_add_button("🗺️  " + LocalizationManager.tr_key("world_select"), Vector2(82, 1050), Vector2(916, 108), func() -> void: SceneManager.change_scene("res://scenes/world_select/WorldSelect.tscn"), 40)
	_add_button("🧪  " + LocalizationManager.tr_key("skins"), Vector2(82, 1180), Vector2(442, 104), func() -> void: SceneManager.change_scene("res://scenes/shop/Shop.tscn"), 38)
	_add_button("⚙️  " + LocalizationManager.tr_key("settings"), Vector2(556, 1180), Vector2(442, 104), func() -> void: SceneManager.change_scene("res://scenes/settings/Settings.tscn"), 38)
	_add_button("❔  " + LocalizationManager.tr_key("about"), Vector2(82, 1304), Vector2(916, 100), func() -> void: SceneManager.change_scene("res://scenes/about/About.tscn"), 36)


func _draw() -> void:
	_draw_strategy_map()


func _stats_text() -> String:
	return "⬆ %s %d     ⭐ %s %d\n🟡 %s %d     📊 %s %.0f%%" % [
		LocalizationManager.tr_key("player_level"),
		int(SaveManager.data.get("player_level", 1)),
		LocalizationManager.tr_key("stars"),
		SaveManager.get_total_stars(),
		LocalizationManager.tr_key("coins"),
		int(SaveManager.data.get("total_coins", 0)),
		LocalizationManager.tr_key("progress"),
		SaveManager.get_progress_percent()
	]


func _add_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.12)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.show_behind_parent = true
	add_child(bg)

	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(1080, 455)
	top.color = Color(0.18, 0.05, 0.36)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.show_behind_parent = true
	add_child(top)


func _draw_strategy_map() -> void:
	for index in range(13):
		var y := 164 + index * 102
		draw_line(Vector2(44, y), Vector2(1036, y - 60), Color(0.46, 0.14, 0.86, 0.36), 2.0)
	for index in range(8):
		var x := 90 + index * 136
		draw_line(Vector2(x, 150), Vector2(x - 90, 1470), Color(0.18, 0.38, 1.0, 0.22), 2.0)

	var nodes := [
		Vector2(112, 276),
		Vector2(280, 340),
		Vector2(428, 280),
		Vector2(576, 370),
		Vector2(752, 314)
	]
	for index in range(nodes.size() - 1):
		draw_line(nodes[index], nodes[index + 1], Color(1.0, 0.82, 0.28, 0.72), 8.0)
	for index in range(nodes.size()):
		var color: Color = Color(0.88, 0.12, 0.9) if index < 3 else Color(1.0, 0.68, 0.12)
		var pulse: float = sin(monster_time * 2.8 + float(index)) * 2.0
		draw_circle(nodes[index], 23.0 + pulse, color)
		draw_arc(nodes[index], 27.0 + pulse, 0.0, TAU, 32, Color(1, 1, 1, 0.65), 4.0)

	draw_rect(Rect2(Vector2(58, 842), Vector2(964, 592)), Color(0.04, 0.025, 0.12, 0.66), true)
	draw_rect(Rect2(Vector2(58, 842), Vector2(964, 592)), Color(0.92, 0.14, 0.92, 0.34), false, 4.0)


func _add_button(text: String, pos: Vector2, size: Vector2, callback: Callable, font_size: int = 36) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.z_index = 10
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", font_size)
	button.pivot_offset = size * 0.5
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx("button", 5)
		callback.call()
	)
	button.mouse_entered.connect(func() -> void:
		if not bool(SaveManager.get_setting("reduced_motion", false)):
			create_tween().tween_property(button, "scale", Vector2(1.025, 1.025), 0.08)
	)
	button.mouse_exited.connect(func() -> void:
		if not bool(SaveManager.get_setting("reduced_motion", false)):
			create_tween().tween_property(button, "scale", Vector2.ONE, 0.08)
	)
	add_child(button)
	action_buttons.append({"button": button, "callback": callback})


func _label(text: String, pos: Vector2, size: Vector2, font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94))
	return label


func _clear() -> void:
	for child in get_children():
		child.queue_free()


func handle_pointer_release(position: Vector2) -> bool:
	for item in action_buttons:
		var button: Button = item.get("button") as Button
		if button == null or button.disabled or not button.visible:
			continue
		if button.get_global_rect().has_point(position):
			AudioManager.play_sfx("button", 5)
			var callback: Callable = item.get("callback")
			if callback.is_valid():
				var viewport: Viewport = get_viewport()
				if viewport != null:
					viewport.set_input_as_handled()
				callback.call()
				return true
	return false
