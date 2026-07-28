extends Node2D

var gravity := 2100.0
var simulation_step := 0.08
var point_count := 24
var active := false
var aim_origin := Vector2.ZERO
var launch_velocity := Vector2.ZERO
var power := 0.0


func set_aim(is_active: bool, origin: Vector2, velocity: Vector2, normalized_power: float) -> void:
	active = is_active and bool(SaveManager.get_setting("aim_guide_enabled", true))
	aim_origin = origin
	launch_velocity = velocity
	power = clampf(normalized_power, 0.0, 1.0)
	queue_redraw()


func clear() -> void:
	active = false
	queue_redraw()


func _draw() -> void:
	if not active or launch_velocity.length() < 1.0:
		return
	var points: Array[Vector2] = []
	var pos := aim_origin
	var vel := launch_velocity
	for _index in range(point_count):
		points.append(pos)
		pos += vel * simulation_step
		vel.y += gravity * simulation_step
	for index in range(points.size()):
		var ratio := float(index) / float(max(1, points.size() - 1))
		var color: Color = Color(lerpf(0.1, 1.0, power), lerpf(0.95, 0.55, power), 0.78, lerpf(0.92, 0.2, ratio))
		draw_circle(points[index], lerpf(10.0, 4.0, ratio), color)
	var arrow_end := aim_origin + launch_velocity.normalized() * lerpf(80.0, 180.0, power)
	draw_line(aim_origin, arrow_end, Color(1.0, 0.95 - power * 0.25, 0.25 + power * 0.25, 0.95), 8.0 + power * 8.0)
