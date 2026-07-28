extends Control

var skin_id := "green"
var jelly_color := Color(0.34, 0.96, 0.74)
var pulse := 0.0
var happy := true


func setup(new_skin_id: String, color: Color, is_happy: bool = true) -> void:
	skin_id = new_skin_id
	jelly_color = color
	happy = is_happy
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5 + Vector2(0, sin(pulse * 2.4) * 5.0)
	var radius: float = min(size.x, size.y) * 0.31
	var squash: Vector2 = Vector2(1.0 + sin(pulse * 3.0) * 0.035, 1.0 - sin(pulse * 3.0) * 0.03)
	draw_set_transform(center, 0.0, squash)
	_draw_body(Vector2.ZERO, radius)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_skin_badge(center, radius)


func _draw_body(center: Vector2, radius: float) -> void:
	var points := PackedVector2Array()
	for index in range(56):
		var angle: float = float(index) / 56.0 * TAU
		var wobble: float = sin(angle * 5.0 + pulse * 5.0) * 3.0 + sin(angle * 3.0 - pulse * 3.2) * 1.6
		var r: float = radius + wobble
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	var outline_points: PackedVector2Array = points.duplicate()
	outline_points.append(points[0])
	draw_colored_polygon(points, jelly_color)
	draw_polyline(outline_points, jelly_color.darkened(0.55), 5.0)
	draw_circle(center + Vector2(-radius * 0.24, -radius * 0.34), radius * 0.16, Color(1, 1, 1, 0.92))
	draw_circle(center + Vector2(radius * 0.24, -radius * 0.34), radius * 0.16, Color(1, 1, 1, 0.92))
	draw_circle(center + Vector2(-radius * 0.24, -radius * 0.34), radius * 0.065, Color(0.04, 0.07, 0.08))
	draw_circle(center + Vector2(radius * 0.24, -radius * 0.34), radius * 0.065, Color(0.04, 0.07, 0.08))
	var mouth_y: float = radius * 0.08
	if happy:
		draw_arc(center + Vector2(0, mouth_y), radius * 0.24, 0.12, PI - 0.12, 22, Color(0.04, 0.07, 0.08), 4.0)
	else:
		draw_line(center + Vector2(-radius * 0.17, mouth_y), center + Vector2(radius * 0.17, mouth_y - 3.0), Color(0.04, 0.07, 0.08), 4.0)
	draw_circle(center + Vector2(-radius * 0.27, radius * 0.42), radius * 0.18, jelly_color.lightened(0.16))
	draw_circle(center + Vector2(radius * 0.27, radius * 0.42), radius * 0.18, jelly_color.lightened(0.16))
	draw_arc(center + Vector2(-radius * 0.18, -radius * 0.2), radius * 0.52, 3.7, 4.85, 24, Color(1, 1, 1, 0.2), 6.0)


func _draw_skin_badge(center: Vector2, radius: float) -> void:
	if skin_id == "king":
		var y: float = center.y - radius * 1.03
		var crown := PackedVector2Array([
			Vector2(center.x - 45, y + 24),
			Vector2(center.x - 30, y - 18),
			Vector2(center.x, y + 10),
			Vector2(center.x + 30, y - 18),
			Vector2(center.x + 45, y + 24)
		])
		draw_colored_polygon(crown, Color(1.0, 0.82, 0.18))
		draw_polyline(crown, Color(0.55, 0.34, 0.04), 3.0)
	elif skin_id == "ninja":
		draw_rect(Rect2(center + Vector2(-radius * 0.48, -radius * 0.42), Vector2(radius * 0.96, radius * 0.22)), Color(0.03, 0.04, 0.05, 0.82), true)
	elif skin_id == "robot":
		draw_rect(Rect2(center + Vector2(-radius * 0.52, -radius * 0.1), Vector2(radius * 1.04, radius * 0.28)), Color(0.78, 0.9, 1.0, 0.55), false, 4.0)
	elif skin_id == "fire":
		_draw_flame(center + Vector2(radius * 0.48, -radius * 0.82), radius * 0.22)
	elif skin_id == "ice":
		draw_arc(center, radius * 0.78, -0.25, 1.1, 18, Color(0.86, 1.0, 1.0, 0.75), 5.0)
	elif skin_id == "space":
		draw_circle(center + Vector2(radius * 0.48, -radius * 0.74), radius * 0.11, Color(1, 1, 1, 0.9))
	elif skin_id == "rainbow":
		var rainbow_colors: Array[Color] = [Color(1.0, 0.22, 0.22), Color(1.0, 0.84, 0.18), Color(0.24, 0.78, 0.34), Color(0.32, 0.58, 1.0)]
		for index in range(4):
			draw_arc(center + Vector2(0, -radius * 0.78), radius * (0.42 + index * 0.08), PI, TAU, 20, rainbow_colors[index], 4.0)


func _draw_flame(center: Vector2, radius: float) -> void:
	var flame := PackedVector2Array([
		center + Vector2(0, -radius * 1.4),
		center + Vector2(radius * 0.9, radius * 0.2),
		center + Vector2(0, radius * 1.0),
		center + Vector2(-radius * 0.9, radius * 0.2)
	])
	draw_colored_polygon(flame, Color(1.0, 0.34, 0.08))
	draw_circle(center + Vector2(0, radius * 0.15), radius * 0.42, Color(1.0, 0.86, 0.24))
