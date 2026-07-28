extends Area2D

var config: Dictionary = {}
var area_type := ""
var size := Vector2(120, 120)
var target := Vector2.ZERO


func setup(area_config: Dictionary) -> void:
	config = area_config
	area_type = String(config.get("type", "hazard"))
	position = _vec(config.get("position", [0, 0]))
	size = _vec(config.get("size", [120, 120]))
	target = _vec(config.get("target", [0, 0]))
	collision_layer = 0
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collision.shape = rect
	add_child(collision)
	add_to_group("effect_area")
	if area_type in ["heat", "toxic", "blade", "patrol", "cannon", "final_core"]:
		add_to_group("hazard_area")
	body_entered.connect(_on_body_entered)
	queue_redraw()


func contains_point(world_position: Vector2) -> bool:
	var local := to_local(world_position)
	return Rect2(-size * 0.5, size).has_point(local)


func get_force_for(world_position: Vector2) -> Vector2:
	if not contains_point(world_position):
		return Vector2.ZERO
	if area_type in ["wind", "jet", "sand", "sticky_boost"]:
		return _vec(config.get("force", [0, 0]))
	if area_type == "magnet_pull" or area_type == "magnet_push":
		var direction := (global_position - world_position).normalized()
		if area_type == "magnet_push":
			direction = -direction
		return direction * float(config.get("strength", 800))
	return Vector2.ZERO


func get_gravity_override(world_position: Vector2, fallback: float) -> float:
	if contains_point(world_position) and area_type == "gravity":
		return float(config.get("gravity", fallback))
	return fallback


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if area_type == "portal" and target != Vector2.ZERO:
		body.global_position = target
		AudioManager.play_sfx("portal", 18)


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	var color: Color = Color(0.4, 0.8, 1.0, 0.13)
	var outline: Color = Color(0.6, 0.95, 1.0, 0.36)
	if area_type in ["heat", "toxic", "blade", "patrol", "cannon", "final_core"]:
		color = Color(1.0, 0.15, 0.12, 0.18)
		outline = Color(1.0, 0.52, 0.42, 0.55)
	elif area_type.begins_with("magnet"):
		color = Color(0.72, 0.45, 1.0, 0.18)
		outline = Color(0.9, 0.72, 1.0, 0.5)
	elif area_type == "portal":
		color = Color(0.55, 0.18, 1.0, 0.24)
		outline = Color(0.86, 0.62, 1.0, 0.72)
	elif area_type == "slow_time":
		color = Color(1.0, 0.34, 0.78, 0.12)
		outline = Color(1.0, 0.66, 0.9, 0.38)
	draw_rect(rect, color, true)
	draw_rect(rect, outline, false, 4.0)


func _vec(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
