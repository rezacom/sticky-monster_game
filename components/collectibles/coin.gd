extends Area2D

signal collected(index: int)

var index := 0
var taken := false
var pulse := 0.0
var base_position := Vector2.ZERO
var motion_axis := "none"
var motion_distance := 0.0
var motion_speed := 0.0


func setup(coin_index: int, world_position: Vector2, motion: Dictionary = {}) -> void:
	index = coin_index
	position = world_position
	base_position = world_position
	motion_axis = String(motion.get("axis", "none"))
	motion_distance = float(motion.get("distance", 0.0))
	motion_speed = float(motion.get("speed", 0.0))
	collision_layer = 0
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 34
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	if motion_distance > 0.0 and motion_axis != "none":
		var offset := sin(pulse * max(0.1, motion_speed)) * motion_distance
		position = base_position + (Vector2(offset, 0) if motion_axis == "x" else Vector2(0, offset))
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if taken or not body.is_in_group("player"):
		return
	taken = true
	AudioManager.play_sfx("coin", 12)
	emit_signal("collected", index)
	queue_free()


func _draw() -> void:
	var scale := 1.0 + sin(pulse * 5.0) * 0.08
	draw_circle(Vector2.ZERO, 32.0 * scale, Color(1.0, 0.78, 0.16))
	draw_circle(Vector2.ZERO, 20.0 * scale, Color(1.0, 0.93, 0.42))
	draw_arc(Vector2.ZERO, 31.0 * scale, 0, TAU, 36, Color(0.62, 0.38, 0.05), 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(-13, 13), "⭐", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
