extends Control

var world_id := 1


func setup(args: Dictionary) -> void:
	world_id = int(args.get("world_id", AppManager.selected_world_id))
	_build()


func _ready() -> void:
	if get_child_count() == 0:
		_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var world: Dictionary = GameData.get_world(world_id)
	var color: Color = GameData.color_from_hex(String(world.get("color", "55f0a2")), Color(0.2, 0.8, 0.6))
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = color.darkened(0.78)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var name: String = String(world.get("name_en", "World"))
	if LocalizationManager.language == "fa":
		name = String(world.get("name_fa", name))
	var title := Label.new()
	title.position = Vector2(52, 62)
	title.size = Vector2(760, 82)
	title.text = name
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.94, 1.0, 0.96))
	add_child(title)
	var back := Button.new()
	back.position = Vector2(804, 64)
	back.size = Vector2(220, 68)
	back.text = LocalizationManager.tr_key("back")
	back.pressed.connect(SceneManager.go_back)
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(44, 180)
	scroll.size = Vector2(992, 1600)
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	scroll.add_child(grid)

	for level_data in GameData.get_levels_for_world(world_id):
		var level_id: int = int(level_data.get("id", 1))
		var record: Dictionary = SaveManager.get_level_record(level_id)
		var unlocked: bool = SaveManager.is_level_unlocked(level_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(462, 220)
		button.disabled = not unlocked
		button.text = "🎯 %s %d\n⭐ %d    🏁 %d\n🟡 %d/%d%s" % [
			LocalizationManager.tr_key("level"),
			level_id,
			int(record.get("stars", 0)),
			int(record.get("best_launches", 0)),
			record.get("coins", []).size(),
			level_data.get("coins", []).size(),
			"" if unlocked else "\n" + LocalizationManager.tr_key("locked")
		]
		button.pressed.connect(func(id := level_id) -> void:
			AudioManager.play_sfx("button", 5)
			AppManager.start_level(id)
		)
		grid.add_child(button)
