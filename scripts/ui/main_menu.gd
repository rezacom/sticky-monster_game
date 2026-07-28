extends Control

var monster_time := 0.0
var monster_color := Color(0.34, 0.96, 0.74)
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
	var title := _label(LocalizationManager.tr_key("game_title"), Vector2(60, 72), Vector2(960, 118), 86, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.42))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	var skin: Dictionary = GameData.get_skin(String(SaveManager.data.get("selected_skin", "green")))
	monster_color = GameData.color_from_hex(String(skin.get("color", "55f0a2")), Color(0.34, 0.96, 0.74))

	var stats_panel := PanelContainer.new()
	stats_panel.position = Vector2(90, 510)
	stats_panel.size = Vector2(900, 230)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stats_panel)
	var stats := _label(_stats_text(), Vector2.ZERO, Vector2(840, 188), 36, HORIZONTAL_ALIGNMENT_CENTER)
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_panel.add_child(stats)

	var xp_bar := ProgressBar.new()
	xp_bar.position = Vector2(135, 768)
	xp_bar.size = Vector2(810, 42)
	xp_bar.max_value = GameData.xp_required_for_level(int(SaveManager.data.get("player_level", 1)))
	xp_bar.value = int(SaveManager.data.get("xp", 0))
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_bar)

	var y := 875.0
	_add_button("▶  " + LocalizationManager.tr_key("continue"), Vector2(100, y), Vector2(880, 112), Callable(AppManager, "continue_game"), 42)
	y += 135
	_add_button("▦  " + LocalizationManager.tr_key("world_select"), Vector2(100, y), Vector2(880, 104), func() -> void: SceneManager.change_scene("res://scenes/world_select/WorldSelect.tscn"), 40)
	y += 124
	_add_button("●  " + LocalizationManager.tr_key("skins"), Vector2(100, y), Vector2(420, 100), func() -> void: SceneManager.change_scene("res://scenes/shop/Shop.tscn"), 38)
	_add_button("⚙  " + LocalizationManager.tr_key("settings"), Vector2(560, y), Vector2(420, 100), func() -> void: SceneManager.change_scene("res://scenes/settings/Settings.tscn"), 38)
	y += 120
	_add_button("؟  " + LocalizationManager.tr_key("about"), Vector2(100, y), Vector2(880, 100), func() -> void: SceneManager.change_scene("res://scenes/about/About.tscn"), 38)


func _draw() -> void:
	var bob := sin(monster_time * 2.2) * 12.0
	var center := Vector2(540, 350 + bob)
	var star_colors: Array[Color] = [
		Color(1.0, 0.72, 0.28, 0.18),
		Color(0.42, 0.9, 1.0, 0.16),
		Color(1.0, 0.44, 0.68, 0.16)
	]
	for index in range(12):
		var x := 70 + ((index * 151) % 940)
		var y := 210 + ((index * 227) % 1160)
		var color: Color = star_colors[index % star_colors.size()]
		_draw_star(Vector2(x, y), 13 + (index % 4) * 4, color)
	draw_circle(center, 108, monster_color)
	draw_arc(center, 108, 0, TAU, 72, monster_color.darkened(0.55), 7.0)
	draw_circle(center + Vector2(-62, 68), 22, monster_color.lightened(0.18))
	draw_circle(center + Vector2(62, 68), 22, monster_color.lightened(0.18))
	var blink := fmod(monster_time, 3.8) < 0.11
	if blink:
		draw_line(center + Vector2(-48, -30), center + Vector2(-12, -30), Color(0.04, 0.08, 0.09), 6.0)
		draw_line(center + Vector2(12, -30), center + Vector2(48, -30), Color(0.04, 0.08, 0.09), 6.0)
	else:
		draw_circle(center + Vector2(-30, -30), 13, Color(0.04, 0.08, 0.09))
		draw_circle(center + Vector2(30, -30), 13, Color(0.04, 0.08, 0.09))
	draw_arc(center + Vector2(0, 12), 34, 0.15, PI - 0.15, 28, Color(0.04, 0.08, 0.09), 6.0)


func _stats_text() -> String:
	return "⬆ %s %d     ★ %s %d\n● %s %d     ٪ %s %.0f" % [
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
	bg.color = Color(0.07, 0.16, 0.16)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var top := ColorRect.new()
	top.position = Vector2(0, 0)
	top.size = Vector2(1080, 420)
	top.color = Color(0.15, 0.55, 0.5)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)


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


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var r := radius if i % 2 == 0 else radius * 0.48
		var angle := -PI * 0.5 + float(i) * PI / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)


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
