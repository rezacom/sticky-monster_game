extends Control

const JELLY_AVATAR_SCRIPT := preload("res://scripts/ui/jelly_avatar.gd")


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.025, 0.018, 0.11)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.show_behind_parent = true
	add_child(bg)

	var title := Label.new()
	title.position = Vector2(48, 50)
	title.size = Vector2(720, 90)
	title.text = "🧪 %s    🟡 %d" % [LocalizationManager.tr_key("skins"), int(SaveManager.data.get("total_coins", 0))]
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.38))
	add_child(title)

	var back := Button.new()
	back.position = Vector2(804, 60)
	back.size = Vector2(220, 76)
	back.text = LocalizationManager.tr_key("back")
	back.add_theme_font_size_override("font_size", 34)
	back.pressed.connect(SceneManager.go_back)
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(42, 166)
	scroll.size = Vector2(996, 1588)
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 24)
	scroll.add_child(grid)

	for skin in GameData.skins:
		var skin_id: String = String(skin.get("id", "green"))
		var owned: bool = SaveManager.is_skin_unlocked(skin_id)
		var selected: bool = String(SaveManager.data.get("selected_skin", "green")) == skin_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(468, 310)
		button.add_theme_font_size_override("font_size", 30)
		button.modulate = Color(1, 1, 1, 1) if owned else Color(0.68, 0.72, 0.72, 1)

		var name: String = String(skin.get("name_en", skin_id))
		if LocalizationManager.language == "fa":
			name = String(skin.get("name_fa", name))
		var action: String = "✅ " + LocalizationManager.tr_key("selected") if selected else ("🛡️ " + LocalizationManager.tr_key("select") if owned else "🔒 " + _unlock_text(skin))
		button.text = "\n\n\n\n%s\n%s" % [name, action]

		var avatar := Control.new()
		avatar.position = Vector2(124, 16)
		avatar.size = Vector2(220, 168)
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar.set_script(JELLY_AVATAR_SCRIPT)
		button.add_child(avatar)
		var color: Color = GameData.color_from_hex(String(skin.get("color", "ffffff")), Color.WHITE)
		avatar.call("setup", skin_id, color, owned)

		button.pressed.connect(func(id := skin_id) -> void:
			if SaveManager.is_skin_unlocked(id):
				SaveManager.select_skin(id)
			else:
				SaveManager.buy_skin(id)
			_build()
		)
		grid.add_child(button)


func _draw() -> void:
	for index in range(9):
		var y := 220 + index * 165
		draw_line(Vector2(70, y), Vector2(1010, y - 80), Color(0.62, 0.12, 0.94, 0.24), 4.0)
	for index in range(18):
		var center := Vector2(92 + ((index * 211) % 900), 238 + ((index * 149) % 1360))
		draw_circle(center, 9.0 + (index % 3) * 3.0, Color(1.0, 0.68, 0.14, 0.2))


func _unlock_text(skin: Dictionary) -> String:
	var unlock: String = String(skin.get("unlock", "coins"))
	if unlock == "coins":
		return "%s %d" % [LocalizationManager.tr_key("buy"), int(skin.get("price", 0))]
	if unlock == "level":
		return "%s %d" % [LocalizationManager.tr_key("level"), int(skin.get("level", 1))]
	if unlock == "stars":
		return "%s %d" % [LocalizationManager.tr_key("stars"), int(skin.get("stars", 0))]
	if unlock == "world":
		return "World %d" % int(skin.get("world", 1))
	return LocalizationManager.tr_key("locked")
