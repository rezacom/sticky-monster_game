extends Control

const APP_ICON := preload("res://assets/icons/app_icon.png")


func _ready() -> void:
	_build()
	await get_tree().create_timer(0.55).timeout
	SceneManager.change_scene("res://scenes/main_menu/MainMenu.tscn", {}, false)


func _build() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.06, 0.06)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var icon := TextureRect.new()
	icon.texture = APP_ICON
	icon.position = Vector2(270, 390)
	icon.size = Vector2(540, 540)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)

	var title := Label.new()
	title.position = Vector2(80, 980)
	title.size = Vector2(920, 150)
	title.text = LocalizationManager.tr_key("game_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.36))
	add_child(title)
	LocalizationManager.apply_direction(self)
