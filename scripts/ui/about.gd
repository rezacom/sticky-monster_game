extends Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.052, 0.052)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.position = Vector2(60, 80)
	title.size = Vector2(760, 80)
	title.text = LocalizationManager.tr_key("about")
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.94, 1.0, 0.96))
	add_child(title)
	var body := Label.new()
	body.position = Vector2(86, 230)
	body.size = Vector2(900, 760)
	body.text = LocalizationManager.tr_key("about_text")
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 32)
	body.add_theme_color_override("font_color", Color(0.88, 0.96, 0.92))
	add_child(body)
	var back := Button.new()
	back.position = Vector2(804, 74)
	back.size = Vector2(220, 68)
	back.text = LocalizationManager.tr_key("back")
	back.pressed.connect(SceneManager.go_back)
	add_child(back)
