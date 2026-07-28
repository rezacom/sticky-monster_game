extends Control


func _ready() -> void:
	_build()


func _build() -> void:
	_add_background()
	add_child(_title(LocalizationManager.tr_key("world_select")))
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(46, 190)
	scroll.size = Vector2(988, 1550)
	add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)
	for world in GameData.worlds:
		var world_id: int = int(world.get("id", 1))
		var stats: Dictionary = SaveManager.get_world_stats(world_id)
		var level_total: int = GameData.get_levels_for_world(world_id).size()
		var star_total: int = level_total * 3
		var unlocked: bool = SaveManager.is_world_unlocked(world_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(960, 130)
		button.disabled = not unlocked
		var name: String = String(world.get("name_en", "World"))
		if LocalizationManager.language == "fa":
			name = String(world.get("name_fa", name))
		button.text = "🌍 %02d  %s\n⭐ %d/%d    🎯 %d/%d    %s" % [
			world_id,
			name,
			int(stats.get("stars", 0)),
			star_total,
			int(stats.get("completed", 0)),
			level_total,
			"" if unlocked else LocalizationManager.tr_key("locked")
		]
		button.pressed.connect(func(id := world_id) -> void:
			AudioManager.play_sfx("button", 5)
			AppManager.open_level_select(id)
		)
		list.add_child(button)
	_add_back()


func _add_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.045, 0.055, 0.06)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _title(text: String) -> Label:
	var label := Label.new()
	label.position = Vector2(56, 70)
	label.size = Vector2(760, 86)
	label.text = text
	label.add_theme_font_size_override("font_size", 54)
	label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94))
	return label


func _add_back() -> void:
	var button := Button.new()
	button.position = Vector2(790, 70)
	button.size = Vector2(220, 70)
	button.text = LocalizationManager.tr_key("back")
	button.pressed.connect(SceneManager.go_back)
	add_child(button)
