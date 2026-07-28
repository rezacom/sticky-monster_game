extends Control


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.046, 0.052)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.position = Vector2(52, 62)
	title.size = Vector2(700, 80)
	title.text = LocalizationManager.tr_key("settings")
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_color", Color(0.94, 1.0, 0.96))
	add_child(title)
	var back := Button.new()
	back.position = Vector2(804, 64)
	back.size = Vector2(220, 68)
	back.text = LocalizationManager.tr_key("back")
	back.pressed.connect(SceneManager.go_back)
	add_child(back)

	var box := VBoxContainer.new()
	box.position = Vector2(90, 190)
	box.size = Vector2(900, 1280)
	box.add_theme_constant_override("separation", 16)
	add_child(box)
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
	reset.custom_minimum_size = Vector2(860, 72)
	reset.pressed.connect(_confirm_reset)
	box.add_child(reset)

	var version := Label.new()
	version.text = "%s 1.0.0" % LocalizationManager.tr_key("version")
	version.add_theme_font_size_override("font_size", 26)
	box.add_child(version)


func _add_check(parent: VBoxContainer, key: String, text: String) -> void:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = bool(SaveManager.get_setting(key, false))
	check.custom_minimum_size = Vector2(860, 64)
	check.toggled.connect(func(value: bool) -> void: SaveManager.update_setting(key, value))
	parent.add_child(check)


func _add_slider(parent: VBoxContainer, key: String, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = float(SaveManager.get_setting(key, 0.75))
	slider.custom_minimum_size = Vector2(860, 46)
	slider.value_changed.connect(func(value: float) -> void: SaveManager.update_setting(key, value))
	parent.add_child(slider)


func _add_option(parent: VBoxContainer, key: String, text: String, options: Array) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(860, 64)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(420, 62)
	label.add_theme_font_size_override("font_size", 26)
	row.add_child(label)
	var option := OptionButton.new()
	option.custom_minimum_size = Vector2(420, 62)
	for item in options:
		option.add_item(String(item))
	var current: String = String(SaveManager.get_setting(key, options[0]))
	option.select(max(0, options.find(current)))
	option.item_selected.connect(func(index: int) -> void:
		var value: String = String(options[index])
		SaveManager.update_setting(key, value)
		if key == "language":
			LocalizationManager.set_language(value)
			_build()
	)
	row.add_child(option)
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
