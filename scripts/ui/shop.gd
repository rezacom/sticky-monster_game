extends Control


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.queue_free()
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.045, 0.05, 0.058)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var title := Label.new()
	title.position = Vector2(52, 62)
	title.size = Vector2(700, 80)
	title.text = "%s    %s: %d" % [LocalizationManager.tr_key("skins"), LocalizationManager.tr_key("coins"), int(SaveManager.data.get("total_coins", 0))]
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.94, 1.0, 0.96))
	add_child(title)
	var back := Button.new()
	back.position = Vector2(804, 64)
	back.size = Vector2(220, 68)
	back.text = LocalizationManager.tr_key("back")
	back.pressed.connect(SceneManager.go_back)
	add_child(back)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(46, 180)
	scroll.size = Vector2(988, 1540)
	add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 22)
	scroll.add_child(grid)

	for skin in GameData.skins:
		var skin_id: String = String(skin.get("id", "green"))
		var owned: bool = SaveManager.is_skin_unlocked(skin_id)
		var selected: bool = String(SaveManager.data.get("selected_skin", "green")) == skin_id
		var button := Button.new()
		button.custom_minimum_size = Vector2(460, 190)
		var name: String = String(skin.get("name_en", skin_id))
		if LocalizationManager.language == "fa":
			name = String(skin.get("name_fa", name))
		var action: String = LocalizationManager.tr_key("selected") if selected else (LocalizationManager.tr_key("select") if owned else _unlock_text(skin))
		button.text = "%s\n%s" % [name, action]
		button.modulate = GameData.color_from_hex(String(skin.get("color", "ffffff")), Color.WHITE).lightened(0.08)
		button.pressed.connect(func(id := skin_id) -> void:
			if SaveManager.is_skin_unlocked(id):
				SaveManager.select_skin(id)
			else:
				SaveManager.buy_skin(id)
			_build()
		)
		grid.add_child(button)


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
