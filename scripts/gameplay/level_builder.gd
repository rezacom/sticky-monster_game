extends Node2D

signal coin_collected(index: int)
signal exit_reached
signal hazard_hit

const BLOCK_SCRIPT := preload("res://components/obstacles/level_block.gd")
const COIN_SCRIPT := preload("res://components/collectibles/coin.gd")
const AREA_SCRIPT := preload("res://components/areas/effect_area.gd")

var level_data: Dictionary = {}
var world_data: Dictionary = {}
var world_color := Color(0.28, 0.8, 0.62)
var effect_areas: Array = []
var exit_position := Vector2.ZERO


func build(new_level_data: Dictionary, new_world_data: Dictionary) -> void:
	level_data = new_level_data
	world_data = new_world_data
	world_color = GameData.color_from_hex(String(world_data.get("color", "55f0a2")), Color(0.28, 0.8, 0.62))
	for child in get_children():
		child.queue_free()
	effect_areas.clear()
	_create_background()
	_create_bounds()
	_create_blocks()
	_create_areas()
	_create_hazards()
	_create_coins()
	_create_exit()


func get_start_position() -> Vector2:
	return _vec(level_data.get("start", [540, 1765]))


func get_environment_force(world_position: Vector2) -> Vector2:
	var force := Vector2.ZERO
	for area in effect_areas:
		force += area.get_force_for(world_position)
	return force


func get_gravity_override(world_position: Vector2, fallback: float) -> float:
	var result := fallback
	for area in effect_areas:
		result = area.get_gravity_override(world_position, result)
	return result


func _create_background() -> void:
	var background := Node2D.new()
	background.name = "Background"
	background.set_script(load("res://scripts/gameplay/level_background.gd"))
	add_child(background)
	background.call("setup", world_color, int(level_data.get("world", 1)))


func _create_bounds() -> void:
	var bounds := [
		{"type": "sticky", "position": [35, 960], "size": [70, 1920]},
		{"type": "sticky", "position": [1045, 960], "size": [70, 1920]},
		{"type": "sticky", "position": [540, 1888], "size": [1080, 72]},
		{"type": "solid", "position": [540, -36], "size": [1080, 72]}
	]
	for block_config in bounds:
		_add_block(block_config)


func _create_blocks() -> void:
	for block_config in level_data.get("blocks", []):
		if _is_too_close_to_spawn(block_config):
			continue
		_add_block(block_config)


func _create_areas() -> void:
	for area_config in level_data.get("areas", []):
		_add_area(area_config)


func _create_hazards() -> void:
	for hazard_config in level_data.get("hazards", []):
		var area := _add_area(hazard_config)
		area.body_entered.connect(func(body: Node2D) -> void:
			if body.is_in_group("player"):
				emit_signal("hazard_hit")
		)


func _create_coins() -> void:
	var index := 0
	for coin_config in level_data.get("coins", []):
		var coin := Area2D.new()
		coin.set_script(COIN_SCRIPT)
		add_child(coin)
		coin.call("setup", index, _coin_position(coin_config), _coin_motion(coin_config))
		coin.collected.connect(func(coin_index: int) -> void: emit_signal("coin_collected", coin_index))
		index += 1


func _create_exit() -> void:
	exit_position = _vec(level_data.get("exit", [540, 230]))
	var exit := Area2D.new()
	exit.name = "Exit"
	exit.position = exit_position
	exit.collision_layer = 0
	exit.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 72
	shape.shape = circle
	exit.add_child(shape)
	exit.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			AudioManager.play_sfx("exit", 28)
			emit_signal("exit_reached")
	)
	exit.set_script(load("res://scripts/gameplay/exit_visual.gd"))
	add_child(exit)
	exit.call("setup_motion", level_data.get("exit_motion", {}))


func _add_block(block_config: Dictionary) -> Node2D:
	var block := StaticBody2D.new()
	block.set_script(BLOCK_SCRIPT)
	add_child(block)
	block.call("setup", block_config, world_color)
	return block


func _is_too_close_to_spawn(block_config: Dictionary) -> bool:
	var block_position: Vector2 = _vec(block_config.get("position", [0, 0]))
	var block_size: Vector2 = _vec(block_config.get("size", [0, 0]))
	var spawn_clearance: float = 110.0
	var spawn_rect: Rect2 = Rect2(get_start_position() - Vector2.ONE * spawn_clearance, Vector2.ONE * spawn_clearance * 2.0)
	var block_rect: Rect2 = Rect2(block_position - block_size * 0.5, block_size).grow(26.0)
	return spawn_rect.intersects(block_rect)


func _add_area(area_config: Dictionary) -> Area2D:
	var area := Area2D.new()
	area.set_script(AREA_SCRIPT)
	add_child(area)
	area.call("setup", area_config)
	effect_areas.append(area)
	return area


func _vec(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


func _coin_position(value: Variant) -> Vector2:
	if value is Dictionary:
		return _vec(value.get("position", [0, 0]))
	return _vec(value)


func _coin_motion(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.get("motion", {})
	return {}
