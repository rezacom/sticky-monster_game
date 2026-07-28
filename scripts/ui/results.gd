extends Control

var result: Dictionary = {}


func setup(args: Dictionary) -> void:
	result = args
	_build()


func _ready() -> void:
	if result.is_empty():
		result = AppManager.last_result
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.048, 0.052)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var success: bool = bool(result.get("success", false))
	var title := Label.new()
	title.position = Vector2(80, 120)
	title.size = Vector2(920, 130)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = LocalizationManager.tr_key("success") if success else LocalizationManager.tr_key("failed")
	title.add_theme_font_size_override("font_size", 62)
	title.add_theme_color_override("font_color", Color(0.96, 0.88, 0.38) if success else Color(1.0, 0.46, 0.42))
	add_child(title)

	var info := Label.new()
	info.position = Vector2(110, 310)
	info.size = Vector2(860, 420)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if success:
		info.text = "%s %d\n%s: %d\n%s: %d\n%s: %d\n%s: %d" % [
			LocalizationManager.tr_key("level"),
			int(result.get("level_id", 1)),
			LocalizationManager.tr_key("stars"),
			int(result.get("stars", 0)),
			LocalizationManager.tr_key("launches"),
			int(result.get("launches", 0)),
			LocalizationManager.tr_key("coins"),
			int(result.get("coin_reward", 0)),
			LocalizationManager.tr_key("xp"),
			int(result.get("xp", 0))
		]
	else:
		info.text = "%s\n%s" % [String(result.get("reason", "")), LocalizationManager.tr_key("retry")]
	info.add_theme_font_size_override("font_size", 36)
	info.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94))
	add_child(info)

	var y := 850.0
	if success and int(result.get("level_id", 1)) < GameData.get_level_count():
		_add_button(LocalizationManager.tr_key("next_level"), Vector2(170, y), Vector2(740, 80), func() -> void: AppManager.start_level(int(result.get("level_id", 1)) + 1))
		y += 104
	_add_button(LocalizationManager.tr_key("retry"), Vector2(170, y), Vector2(740, 80), func() -> void: AppManager.start_level(int(result.get("level_id", 1))))
	y += 104
	_add_button(LocalizationManager.tr_key("level_select"), Vector2(170, y), Vector2(740, 80), func() -> void:
		var level: Dictionary = GameData.get_level(int(result.get("level_id", 1)))
		AppManager.open_level_select(int(level.get("world", 1)))
	)
	y += 104
	_add_button(LocalizationManager.tr_key("main_menu"), Vector2(170, y), Vector2(740, 80), func() -> void: SceneManager.change_scene("res://scenes/main_menu/MainMenu.tscn"))


func _add_button(text: String, pos: Vector2, size: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = size
	button.add_theme_font_size_override("font_size", 30)
	button.pressed.connect(func() -> void:
		AudioManager.play_sfx("button", 5)
		callback.call()
	)
	add_child(button)
