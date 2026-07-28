extends Control


func _ready() -> void:
	_build()


func _build() -> void:
	_add_background()
	add_child(_title("🗺️ " + LocalizationManager.tr_key("world_select")))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(44, 188)
	scroll.size = Vector2(992, 1560)
	add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 22)
	scroll.add_child(list)
	for world in GameData.worlds:
		var world_id: int = int(world.get("id", 1))
		var stats: Dictionary = SaveManager.get_world_stats(world_id)
		var level_total: int = GameData.get_levels_for_world(world_id).size()
		var star_total: int = level_total * 3
		var unlocked: bool = SaveManager.is_world_unlocked(world_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(960, 156)
		button.disabled = not unlocked
		button.add_theme_font_size_override("font_size", 34)
		button.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.62, 0.66, 0.66, 1)
		var name: String = String(world.get("name_en", "World"))
		if LocalizationManager.language == "fa":
			name = String(world.get("name_fa", name))
		var icon: String = _world_icon(world_id)
		var completed: int = int(stats.get("completed", 0))
		button.text = "%s  قلمرو %02d: %s\n⭐ %d/%d     🎯 %d/%d     🧭 %s" % [
			icon,
			world_id,
			name,
			int(stats.get("stars", 0)),
			star_total,
			completed,
			level_total,
			"باز" if unlocked else LocalizationManager.tr_key("locked")
		]
		button.pressed.connect(func(id := world_id) -> void:
			AudioManager.play_sfx("button", 5)
			AppManager.open_level_select(id)
		)
		list.add_child(button)
	_add_back()


func _draw() -> void:
	for index in range(10):
		var x := 110 + (index % 2) * 760
		var y := 240 + index * 150
		draw_circle(Vector2(x, y), 38.0, Color(0.15, 0.36, 0.29, 0.5))
		if index < 9:
			var next: Vector2 = Vector2(870 if index % 2 == 0 else 110, y + 150)
			draw_line(Vector2(x, y), next, Color(1.0, 0.79, 0.28, 0.24), 7.0)


func _add_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.11)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.show_behind_parent = true
	add_child(bg)

	var band := ColorRect.new()
	band.position = Vector2(0, 0)
	band.size = Vector2(1080, 168)
	band.color = Color(0.18, 0.05, 0.36)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.show_behind_parent = true
	add_child(band)


func _title(text: String) -> Label:
	var label := Label.new()
	label.position = Vector2(52, 58)
	label.size = Vector2(730, 86)
	label.text = text
	label.add_theme_font_size_override("font_size", 50)
	label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.38))
	return label


func _add_back() -> void:
	var button := Button.new()
	button.position = Vector2(790, 60)
	button.size = Vector2(230, 76)
	button.text = LocalizationManager.tr_key("back")
	button.add_theme_font_size_override("font_size", 34)
	button.pressed.connect(SceneManager.go_back)
	add_child(button)


func _world_icon(world_id: int) -> String:
	var icons: Array[String] = ["🌱", "🪨", "❄️", "🔥", "🧲", "🌪️", "⚡", "🧊", "🌌", "👑"]
	return icons[clampi(world_id - 1, 0, icons.size() - 1)]
