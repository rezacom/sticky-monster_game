extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.11)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.position = Vector2(60, 64)
	title.size = Vector2(730, 84)
	title.text = LocalizationManager.tr_key("about")
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.38))
	add_child(title)

	var body := Label.new()
	body.position = Vector2(78, 210)
	body.size = Vector2(924, 1120)
	body.text = LocalizationManager.tr_key("about_text")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 34)
	body.add_theme_color_override("font_color", Color(0.94, 0.9, 1.0))
	add_child(body)

	var back := Button.new()
	back.position = Vector2(790, 60)
	back.size = Vector2(230, 78)
	back.text = LocalizationManager.tr_key("back")
	back.add_theme_font_size_override("font_size", 36)
	back.pressed.connect(SceneManager.go_back)
	add_child(back)
	LocalizationManager.apply_direction(self)
