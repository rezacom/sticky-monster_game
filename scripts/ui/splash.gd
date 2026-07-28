extends Control


func _ready() -> void:
	_build()
	await get_tree().create_timer(0.18).timeout
	SceneManager.change_scene("res://scenes/main_menu/MainMenu.tscn", {}, false)


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.06)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.text = LocalizationManager.tr_key("game_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 78)
	title.add_theme_color_override("font_color", Color(0.34, 0.96, 0.74))
	add_child(title)
