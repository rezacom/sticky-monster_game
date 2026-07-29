extends Node2D

const CHARACTER_SCRIPT := preload("res://components/sticky_character/sticky_character.gd")
const BUILDER_SCRIPT := preload("res://scripts/gameplay/level_builder.gd")
const PREVIEW_SCRIPT := preload("res://scripts/gameplay/launch_preview.gd")

var level_id := 1
var level_data: Dictionary = {}
var world_data: Dictionary = {}
var builder: Node2D
var player: CharacterBody2D
var preview: Node2D
var hud: CanvasLayer
var launches_used := 0
var collected_coins: Array = []
var level_finished := false
var paused := false
var out_of_launches_pending := false

var launches_label: Label
var coins_label: Label
var status_label: Label
var power_bar: ProgressBar
var pause_panel: Control


func setup(args: Dictionary) -> void:
	level_id = int(args.get("level_id", 1))
	level_data = GameData.get_level(level_id)
	world_data = GameData.get_world(int(level_data.get("world", 1)))
	_build_scene()


func _ready() -> void:
	if level_data.is_empty():
		setup({"level_id": AppManager.current_level_id})


func _process(_delta: float) -> void:
	if player == null or level_finished:
		return
	player.external_acceleration = builder.get_environment_force(player.global_position)
	player.gravity_override = builder.get_gravity_override(player.global_position, float(level_data.get("physics", {}).get("gravity", GameData.balance.get("player", {}).get("gravity", 2100))))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause() -> void:
	if level_finished:
		return
	paused = not paused
	get_tree().paused = paused
	pause_panel.visible = paused


func _build_scene() -> void:
	for child in get_children():
		child.queue_free()

	builder = Node2D.new()
	builder.name = "LevelBuilder"
	builder.set_script(BUILDER_SCRIPT)
	add_child(builder)
	builder.call("build", level_data, world_data)
	builder.coin_collected.connect(_on_coin_collected)
	builder.exit_reached.connect(_on_exit_reached)
	builder.hazard_hit.connect(_on_hazard_hit)

	preview = Node2D.new()
	preview.name = "LaunchPreview"
	preview.z_index = 8
	preview.set_script(PREVIEW_SCRIPT)
	add_child(preview)

	player = CharacterBody2D.new()
	player.name = "StickyCharacter"
	player.z_index = 12
	player.set_script(CHARACTER_SCRIPT)
	add_child(player)
	player.apply_balance(GameData.balance)
	player.level_bounds = Rect2(Vector2.ZERO, Vector2(1080, 1920))
	var skin: Dictionary = GameData.get_skin(String(SaveManager.data.get("selected_skin", "green")))
	player.set_skin(GameData.color_from_hex(String(skin.get("color", "55f0a2")), Color(0.34, 0.96, 0.74)), String(skin.get("id", "green")))
	player.reset_to(builder.get_start_position())
	player.aim_changed.connect(_on_aim_changed)
	player.launched.connect(_on_launched)
	player.fell_out.connect(_on_fell_out)
	player.hard_hit.connect(_on_hard_hit)
	player.died.connect(_on_player_died)
	player.state_changed.connect(_on_player_state_changed)

	_build_hud()
	_update_hud("Ready")


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "Hud"
	add_child(hud)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	hud.add_child(root)

	power_bar = ProgressBar.new()
	power_bar.position = Vector2(42, 38)
	power_bar.size = Vector2(390, 40)
	power_bar.max_value = 1.0
	power_bar.show_percentage = false
	power_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(power_bar)

	launches_label = _label(Vector2(42, 90), Vector2(430, 52), "", 34)
	root.add_child(launches_label)
	coins_label = _label(Vector2(42, 146), Vector2(430, 52), "", 34)
	root.add_child(coins_label)
	status_label = _label(Vector2(42, 202), Vector2(720, 52), "", 32)
	root.add_child(status_label)

	var pause_button := _button("منو", Vector2(830, 34), Vector2(210, 82), 36)
	pause_button.pressed.connect(toggle_pause)
	root.add_child(pause_button)

	pause_panel = PanelContainer.new()
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.position = Vector2(110, 500)
	pause_panel.size = Vector2(860, 690)
	root.add_child(pause_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	pause_panel.add_child(box)
	var title := _label(Vector2.ZERO, Vector2(780, 72), LocalizationManager.tr_key("pause"), 48)
	box.add_child(title)
	var resume := Button.new()
	resume.text = LocalizationManager.tr_key("resume")
	resume.custom_minimum_size = Vector2(780, 92)
	resume.add_theme_font_size_override("font_size", 38)
	resume.pressed.connect(toggle_pause)
	box.add_child(resume)
	var restart := Button.new()
	restart.text = LocalizationManager.tr_key("restart")
	restart.custom_minimum_size = Vector2(780, 92)
	restart.add_theme_font_size_override("font_size", 38)
	restart.pressed.connect(_restart)
	box.add_child(restart)
	var levels := Button.new()
	levels.text = LocalizationManager.tr_key("level_select")
	levels.custom_minimum_size = Vector2(780, 92)
	levels.add_theme_font_size_override("font_size", 38)
	levels.pressed.connect(func() -> void:
		get_tree().paused = false
		SceneManager.change_scene("res://scenes/level_select/LevelSelect.tscn", {"world_id": int(level_data.get("world", 1))})
	)
	box.add_child(levels)
	var menu := Button.new()
	menu.text = LocalizationManager.tr_key("main_menu")
	menu.custom_minimum_size = Vector2(780, 92)
	menu.add_theme_font_size_override("font_size", 38)
	menu.pressed.connect(func() -> void:
		get_tree().paused = false
		SceneManager.change_scene("res://scenes/main_menu/MainMenu.tscn")
	)
	box.add_child(menu)


func _label(pos: Vector2, size: Vector2, text: String, font_size: int = 28) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.9, 1.0, 0.94))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String, pos: Vector2, size: Vector2, font_size: int = 30) -> Button:
	var button := Button.new()
	button.position = pos
	button.size = size
	button.text = text
	button.add_theme_font_size_override("font_size", font_size)
	button.pressed.connect(func() -> void: AudioManager.play_sfx("button", 5))
	return button


func _on_aim_changed(active: bool, origin: Vector2, velocity: Vector2, power: float) -> void:
	preview.set_aim(active, origin, velocity, power)
	power_bar.value = power


func _on_launched() -> void:
	launches_used += 1
	_update_hud("Flying")
	var max_launches: int = int(level_data.get("max_launches", 5))
	if launches_used >= max_launches:
		out_of_launches_pending = true
		player.input_enabled = false


func _on_coin_collected(index: int) -> void:
	if not collected_coins.has(index):
		collected_coins.append(index)
	_update_hud("Coin")


func _on_exit_reached() -> void:
	if level_finished:
		return
	level_finished = true
	player.celebrate()
	preview.clear()
	var stars: int = GameData.calculate_stars(level_data, launches_used)
	AppManager.complete_current_level(stars, launches_used, collected_coins)


func _on_hazard_hit() -> void:
	if level_finished:
		return
	player.die()
	_fail(LocalizationManager.tr_key("dead"))


func _on_player_died() -> void:
	_fail(LocalizationManager.tr_key("dead"))


func _on_player_state_changed(state: String) -> void:
	if level_finished or not out_of_launches_pending:
		return
	if state == "IDLE" or state == "STICKING":
		_fail(LocalizationManager.tr_key("out_of_launches"))


func _on_fell_out() -> void:
	_fail(LocalizationManager.tr_key("dead"))


func _on_hard_hit(_position: Vector2) -> void:
	if bool(SaveManager.get_setting("reduced_motion", false)):
		return
	var tween := create_tween()
	tween.tween_property(self, "position", Vector2(8, 0), 0.025)
	tween.tween_property(self, "position", Vector2(-6, 0), 0.025)
	tween.tween_property(self, "position", Vector2.ZERO, 0.025)


func _fail(reason: String) -> void:
	if level_finished:
		return
	level_finished = true
	if player != null:
		player.input_enabled = false
	preview.clear()
	AppManager.fail_current_level(reason)


func _restart() -> void:
	get_tree().paused = false
	SceneManager.change_scene("res://scenes/gameplay/Gameplay.tscn", {"level_id": level_id}, false)


func _update_hud(message: String) -> void:
	var max_launches: int = int(level_data.get("max_launches", 5))
	launches_label.text = "↗ %d / %d" % [launches_used, max_launches]
	coins_label.text = "⭐ %d / %d" % [collected_coins.size(), level_data.get("coins", []).size()]
	status_label.text = "★ %s %d" % [LocalizationManager.tr_key("level"), level_id]
