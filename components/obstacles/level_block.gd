extends StaticBody2D

var config: Dictionary = {}
var block_type := "sticky"
var size := Vector2(200, 60)
var base_position := Vector2.ZERO
var time := 0.0
var motion_axis := "x"
var motion_distance := 0.0
var motion_speed := 0.0


func setup(block_config: Dictionary, world_color: Color) -> void:
	config = block_config
	block_type = String(config.get("type", "sticky"))
	position = _vec(config.get("position", [0, 0]))
	base_position = position
	size = _vec(config.get("size", [200, 60]))
	rotation = float(config.get("rotation", 0.0))
	motion_axis = String(config.get("axis", "x"))
	motion_distance = float(config.get("distance", 0.0))
	motion_speed = float(config.get("speed", 0.0))

	if block_type in ["sticky", "moving", "conveyor", "vanishing"]:
		add_to_group("sticky_wall")
	if block_type in ["solid", "ice"]:
		add_to_group("solid_wall")
	if block_type in ["hazard", "hot", "blade"]:
		add_to_group("hazard")
	if block_type == "bounce":
		add_to_group("bounce")

	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	add_child(collision)
	modulate = Color.WHITE
	set_meta("world_color", world_color)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if motion_distance <= 0.0 and block_type != "vanishing":
		return
	time += delta
	if block_type != "vanishing":
		var offset := sin(time * max(0.1, motion_speed) * 0.018) * motion_distance
		position = base_position + (Vector2(offset, 0) if motion_axis == "x" else Vector2(0, offset))
	elif block_type == "vanishing":
		visible = sin(time * 2.0) > -0.35
		set_collision_layer_value(1, visible)


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	var world_color: Color = get_meta("world_color", Color(0.28, 0.8, 0.62))
	var fill := world_color.darkened(0.18)
	var outline := world_color.lightened(0.32)
	if block_type == "solid":
		fill = Color(0.42, 0.46, 0.47)
		outline = Color(0.76, 0.82, 0.82)
	elif block_type == "ice":
		fill = Color(0.55, 0.88, 1.0)
		outline = Color(0.88, 1.0, 1.0)
	elif block_type == "hot":
		fill = Color(1.0, 0.26, 0.12)
		outline = Color(1.0, 0.76, 0.45)
	elif block_type == "bounce":
		fill = Color(0.96, 0.77, 0.22)
		outline = Color(1.0, 0.96, 0.58)
	elif block_type == "blade":
		fill = Color(0.72, 0.12, 0.14)
		outline = Color(1.0, 0.48, 0.42)
	elif block_type == "vanishing":
		fill = Color(0.72, 0.4, 1.0, 0.82)
		outline = Color(0.94, 0.78, 1.0, 0.95)
	draw_rect(rect, fill, true)
	draw_rect(rect, outline, false, 4.0)
	if block_type in ["sticky", "moving", "conveyor", "vanishing"]:
		draw_rect(rect.grow(-12), Color(1, 1, 1, 0.2), false, 3.0)


func _vec(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
