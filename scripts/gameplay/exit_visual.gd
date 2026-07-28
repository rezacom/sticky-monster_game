extends Area2D

var pulse := 0.0
var base_position := Vector2.ZERO
var motion_axis := "none"
var motion_distance := 0.0
var motion_speed := 0.0


func setup_motion(motion: Dictionary) -> void:
	base_position = position
	motion_axis = String(motion.get("axis", "none"))
	motion_distance = float(motion.get("distance", 0.0))
	motion_speed = float(motion.get("speed", 0.0))


func _process(delta: float) -> void:
	pulse += delta
	if motion_distance > 0.0 and motion_axis != "none":
		var offset := sin(pulse * max(0.1, motion_speed)) * motion_distance
		position = base_position + (Vector2(offset, 0) if motion_axis == "x" else Vector2(0, offset))
	queue_redraw()


func _draw() -> void:
	var ring := 1.0 + sin(pulse * 4.0) * 0.08
	draw_circle(Vector2.ZERO, 94.0 * ring, Color(1.0, 0.78, 0.2, 0.16))
	draw_arc(Vector2.ZERO, 84.0 * ring, 0, TAU, 64, Color(1.0, 0.86, 0.28, 0.95), 7.0)
	draw_circle(Vector2.ZERO, 62.0, Color(1.0, 0.86, 0.28, 0.25))
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.96, 0.55, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(-20, 12), "🏁", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 1, 1))
