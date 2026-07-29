extends Control


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.11)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.position = Vector2(52, 58)
	title.size = Vector2(700, 90)
	title.text = LocalizationManager.tr_key("settings")
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.38))
	add_child(title)

	var back := Button.new()
	back.position = Vector2(790, 60)
	back.size = Vector2(230, 78)
	back.text = LocalizationManager.tr_key("back")
	back.add_theme_font_size_override("font_size", 36)
	back.pressed.connect(SceneManager.go_back)
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(58, 172)
	scroll.size = Vector2(964, 1540)
	add_child(scroll)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(920, 0)
	box.add_theme_constant_override("separation", 24)
	scroll.add_child(box)

	_add_check(box, "music_enabled", LocalizationManager.tr_key("music"))
	_add_slider(box, "music_volume", LocalizationManager.tr_key("music_volume"))
	_add_check(box, "sfx_enabled", LocalizationManager.tr_key("sfx"))
	_add_slider(box, "sfx_volume", LocalizationManager.tr_key("sfx_volume"))
	_add_check(box, "vibration_enabled", LocalizationManager.tr_key("vibration"))
	_add_option(box, "quality", LocalizationManager.tr_key("quality"), ["Low", "Medium", "High"])
	_add_option(box, "language", LocalizationManager.tr_key("language"), ["en", "fa"])
	_add_check(box, "aim_guide_enabled", LocalizationManager.tr_key("aim_guide"))
	_add_check(box, "reduced_motion", LocalizationManager.tr_key("reduced_motion"))

	var reset := Button.new()
	reset.text = LocalizationManager.tr_key("reset_progress")
	reset.custom_minimum_size = Vector2(900, 92)
	reset.add_theme_font_size_override("font_size", 36)
	reset.pressed.connect(_confirm_reset)
	box.add_child(reset)

	var version := Label.new()
	version.text = "%s 1.0.0" % LocalizationManager.tr_key("version")
	version.add_theme_font_size_override("font_size", 30)
	version.add_theme_color_override("font_color", Color(0.86, 0.82, 1.0))
	box.add_child(version)
	LocalizationManager.apply_direction(self)


func _add_check(parent: VBoxContainer, key: String, text: String) -> void:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = bool(SaveManager.get_setting(key, false))
	check.custom_minimum_size = Vector2(900, 96)
	check.add_theme_font_size_override("font_size", 38)
	check.toggled.connect(func(value: bool) -> void:
		SaveManager.update_setting(key, value)
		AudioManager.play_sfx("button", 0)
	)
	parent.add_child(check)


func _add_slider(parent: VBoxContainer, key: String, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(900, 46)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.96, 0.9, 1.0))
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = float(SaveManager.get_setting(key, 0.75))
	slider.custom_minimum_size = Vector2(900, 82)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting(key, value))
	parent.add_child(slider)


func _add_option(parent: VBoxContainer, key: String, text: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(900, 92)
	row.add_theme_constant_override("separation", 14)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(360, 86)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	row.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(430, 86)
	option.add_theme_font_size_override("font_size", 36)
	for item in options:
		option.add_item(String(item))
	var current: String = String(SaveManager.get_setting(key, options[0]))
	option.select(max(0, options.find(current)))
	option.item_selected.connect(func(index: int) -> void:
		var value: String = String(options[index])
		SaveManager.update_setting(key, value)
		AudioManager.play_sfx("button", 0)
		if key == "language":
			LocalizationManager.set_language(value)
			_build()
	)
	row.add_child(option)
	var arrow := Label.new()
	arrow.text = "▼"
	arrow.custom_minimum_size = Vector2(76, 86)
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.add_theme_font_size_override("font_size", 42)
	arrow.add_theme_color_override("font_color", Color(1.0, 0.72, 0.14))
	row.add_child(arrow)
	parent.add_child(row)


func _confirm_reset() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = LocalizationManager.tr_key("confirm_reset")
	dialog.confirmed.connect(func() -> void:
		SaveManager.reset_progress()
		_build()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(760, 300))
