extends Node2D

var world_color := Color(0.28, 0.8, 0.62)
var world_id := 1


func setup(color: Color, id: int) -> void:
	world_color = color
	world_id = id
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1920), world_color.darkened(0.82), true)
	for y in range(0, 1920, 120):
		draw_line(Vector2(0, y), Vector2(1080, y), world_color.darkened(0.58), 2.0)
	for x in range(0, 1080, 120):
		draw_line(Vector2(x, 0), Vector2(x, 1920), world_color.darkened(0.64), 2.0)
	for index in range(8):
		var pos := Vector2(120 + ((index * 173 + world_id * 41) % 860), 210 + ((index * 257 + world_id * 83) % 1420))
		draw_circle(pos, 18 + (index % 3) * 9, _alpha(world_color.lightened(0.15), 0.12))
	draw_rect(Rect2(0, 0, 1080, 1920), _alpha(world_color.lightened(0.08), 0.55), false, 8.0)


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
