extends CharacterBody2D

signal aim_changed(active: bool, origin: Vector2, launch_velocity: Vector2, power: float)
signal state_changed(state: String)
signal launched
signal hard_hit(position: Vector2)
signal fell_out
signal died

enum MotionState { IDLE, AIMING, STRETCHING, FLYING, HITTING, STICKING, FALLING, HURT, DEAD, CELEBRATING }

var radius := 48.0
var touch_radius := 132.0
var max_drag_distance := 365.0
var max_assisted_drag_distance := 620.0
var min_launch_distance := 22.0
var launch_multiplier := 7.25
var gravity := 2100.0
var max_speed := 3200.0
var safe_bounds_margin := 340.0
var hard_collision_speed := 1380.0
var level_bounds := Rect2(Vector2.ZERO, Vector2(1080.0, 1920.0))
var external_acceleration := Vector2.ZERO
var skin_color := Color(0.34, 0.96, 0.74, 0.96)
var skin_id := "green"

var motion_state := MotionState.IDLE
var active_touch_index := -1000
var assist_touch_index := -1000
var primary_pointer_position := Vector2.ZERO
var assist_start_position := Vector2.ZERO
var assist_current_position := Vector2.ZERO
var primary_drag_vector := Vector2.ZERO
var drag_vector := Vector2.ZERO
var spawn_position := Vector2.ZERO
var gravity_override := -1.0
var blink_timer := 0.0
var jelly_time := 0.0
var wobble_strength := 0.0
var stick_normal := Vector2.ZERO
var face_mood := "idle"


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = shape
	add_child(collision)
	add_to_group("player")
	set_physics_process(true)


func apply_balance(balance: Dictionary) -> void:
	var player_data: Dictionary = balance.get("player", {})
	radius = float(player_data.get("radius", radius))
	touch_radius = float(player_data.get("touch_radius", touch_radius))
	max_drag_distance = float(player_data.get("max_drag_distance", max_drag_distance))
	max_assisted_drag_distance = float(player_data.get("max_assisted_drag_distance", max_assisted_drag_distance))
	min_launch_distance = float(player_data.get("min_launch_distance", min_launch_distance))
	launch_multiplier = float(player_data.get("launch_multiplier", launch_multiplier))
	gravity = float(player_data.get("gravity", gravity))
	max_speed = float(player_data.get("max_speed", max_speed))
	safe_bounds_margin = float(player_data.get("safe_bounds_margin", safe_bounds_margin))
	hard_collision_speed = float(player_data.get("hard_collision_speed", hard_collision_speed))
	if has_node("CollisionShape2D"):
		($CollisionShape2D.shape as CircleShape2D).radius = radius


func set_skin(color: Color, id: String = "green") -> void:
	skin_color = color
	skin_id = id
	queue_redraw()


func reset_to(world_position: Vector2) -> void:
	global_position = world_position
	spawn_position = world_position
	velocity = Vector2.ZERO
	drag_vector = Vector2.ZERO
	primary_drag_vector = Vector2.ZERO
	active_touch_index = -1000
	assist_touch_index = -1000
	gravity_override = -1.0
	external_acceleration = Vector2.ZERO
	stick_normal = Vector2.ZERO
	face_mood = "idle"
	_set_state(MotionState.IDLE)
	emit_signal("aim_changed", false, global_position, Vector2.ZERO, 0.0)
	queue_redraw()


func celebrate() -> void:
	velocity = Vector2.ZERO
	drag_vector = Vector2.ZERO
	active_touch_index = -1000
	assist_touch_index = -1000
	face_mood = "happy"
	stick_normal = Vector2.ZERO
	_set_state(MotionState.CELEBRATING)
	emit_signal("aim_changed", false, global_position, Vector2.ZERO, 0.0)
	queue_redraw()


func die() -> void:
	velocity = Vector2.ZERO
	face_mood = "hurt"
	stick_normal = Vector2.ZERO
	_set_state(MotionState.DEAD)
	emit_signal("aim_changed", false, global_position, Vector2.ZERO, 0.0)
	queue_redraw()


func can_aim() -> bool:
	return motion_state == MotionState.IDLE or motion_state == MotionState.STICKING


func _input(event: InputEvent) -> void:
	if motion_state == MotionState.DEAD or motion_state == MotionState.CELEBRATING:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_aim(get_global_mouse_position(), -1)
		elif active_touch_index == -1:
			_release_aim()
	elif event is InputEventMouseMotion and active_touch_index == -1:
		_update_aim(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		var touch_point := _screen_to_world(event.position)
		if event.pressed:
			if motion_state == MotionState.AIMING and event.index != active_touch_index and assist_touch_index == -1000:
				_begin_assist(touch_point, event.index)
			else:
				_begin_aim(touch_point, event.index)
		elif active_touch_index == event.index:
			_release_aim()
		elif assist_touch_index == event.index:
			_end_assist()
	elif event is InputEventScreenDrag and active_touch_index == event.index:
		_update_aim(_screen_to_world(event.position))
	elif event is InputEventScreenDrag and assist_touch_index == event.index:
		_update_assist(_screen_to_world(event.position))


func _physics_process(delta: float) -> void:
	blink_timer += delta
	jelly_time += delta
	wobble_strength = move_toward(wobble_strength, 0.0, delta * 1.8)
	if motion_state != MotionState.FLYING and motion_state != MotionState.FALLING and motion_state != MotionState.HITTING:
		queue_redraw()
		return

	var active_gravity: float = gravity_override if gravity_override >= 0.0 else gravity
	velocity.y += active_gravity * delta
	velocity += external_acceleration * delta
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	var collision := move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision)

	if not level_bounds.grow(safe_bounds_margin).has_point(global_position):
		_set_state(MotionState.FALLING)
		emit_signal("fell_out")
	queue_redraw()


func _begin_aim(pointer_world_position: Vector2, pointer_index: int) -> void:
	if active_touch_index != -1000 or not can_aim():
		return
	if global_position.distance_to(pointer_world_position) > touch_radius:
		return
	AudioManager.play_sfx("aim", 8)
	wobble_strength = max(wobble_strength, 0.24)
	active_touch_index = pointer_index
	assist_touch_index = -1000
	primary_pointer_position = pointer_world_position
	velocity = Vector2.ZERO
	_set_state(MotionState.AIMING)
	_update_aim(pointer_world_position)


func _update_aim(pointer_world_position: Vector2) -> void:
	if motion_state != MotionState.AIMING:
		return
	primary_pointer_position = pointer_world_position
	_recalculate_drag()


func _begin_assist(pointer_world_position: Vector2, pointer_index: int) -> void:
	assist_touch_index = pointer_index
	assist_start_position = pointer_world_position
	assist_current_position = pointer_world_position
	_recalculate_drag()


func _update_assist(pointer_world_position: Vector2) -> void:
	if motion_state != MotionState.AIMING:
		return
	assist_current_position = pointer_world_position
	_recalculate_drag()


func _end_assist() -> void:
	assist_touch_index = -1000
	assist_start_position = Vector2.ZERO
	assist_current_position = Vector2.ZERO
	_recalculate_drag()


func _recalculate_drag() -> void:
	primary_drag_vector = primary_pointer_position - global_position
	if primary_drag_vector.length() > max_drag_distance:
		primary_drag_vector = primary_drag_vector.normalized() * max_drag_distance
	var assist_delta := Vector2.ZERO
	if assist_touch_index != -1000:
		assist_delta = assist_current_position - assist_start_position
	drag_vector = primary_drag_vector + assist_delta
	if drag_vector.length() > max_assisted_drag_distance:
		drag_vector = drag_vector.normalized() * max_assisted_drag_distance
	var launch_velocity := -drag_vector * launch_multiplier
	var power := drag_vector.length() / max_drag_distance
	face_mood = "focus"
	emit_signal("aim_changed", true, global_position, launch_velocity, power)
	queue_redraw()


func _release_aim() -> void:
	if motion_state != MotionState.AIMING:
		return
	active_touch_index = -1000
	assist_touch_index = -1000
	var drag_distance := drag_vector.length()
	if drag_distance < min_launch_distance:
		drag_vector = Vector2.ZERO
		primary_drag_vector = Vector2.ZERO
		_set_state(MotionState.STICKING)
		emit_signal("aim_changed", false, global_position, Vector2.ZERO, 0.0)
		queue_redraw()
		return
	velocity = -drag_vector * launch_multiplier
	wobble_strength = 0.82
	stick_normal = Vector2.ZERO
	drag_vector = Vector2.ZERO
	primary_drag_vector = Vector2.ZERO
	face_mood = "fly"
	_set_state(MotionState.STRETCHING)
	_set_state(MotionState.FLYING)
	AudioManager.play_sfx("launch", 18)
	emit_signal("aim_changed", false, global_position, Vector2.ZERO, 0.0)
	emit_signal("launched")
	queue_redraw()


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()
	var normal: Vector2 = collision.get_normal()
	var impact_speed: float = abs(velocity.dot(normal))

	if impact_speed >= hard_collision_speed:
		face_mood = "hurt"
		wobble_strength = 1.0
		emit_signal("hard_hit", global_position)
		AudioManager.play_sfx("hard_hit", 30)
	else:
		wobble_strength = max(wobble_strength, 0.42)
		AudioManager.play_sfx("soft_hit", 8)

	if collider != null and collider.is_in_group("hazard"):
		_set_state(MotionState.HURT)
		die()
		emit_signal("died")
		return

	if collider != null and collider.is_in_group("bounce"):
		stick_normal = Vector2.ZERO
		global_position += normal * 6.0
		velocity = velocity.bounce(normal) * 0.9 + normal * 620.0
		_set_state(MotionState.FLYING)
		return

	if collider != null and collider.is_in_group("sticky_wall"):
		global_position += normal * 2.0
		velocity = Vector2.ZERO
		stick_normal = normal.normalized()
		wobble_strength = max(wobble_strength, 0.72)
		face_mood = "idle"
		_set_state(MotionState.STICKING)
		AudioManager.play_sfx("stick", 12)
		return

	global_position += normal * 5.0
	stick_normal = Vector2.ZERO
	velocity = velocity.bounce(normal) * 0.36
	_set_state(MotionState.HITTING)
	if velocity.length() < 190.0:
		velocity = Vector2.ZERO
		_set_state(MotionState.IDLE)


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * screen_position


func _set_state(new_state: MotionState) -> void:
	motion_state = new_state
	emit_signal("state_changed", MotionState.keys()[new_state])


func _draw() -> void:
	var speed_squash: float = clampf(velocity.length() / max_speed, 0.0, 0.22)
	var aim_power: float = clampf(drag_vector.length() / max_drag_distance, 0.0, 1.0)
	var idle_wobble: float = sin(jelly_time * 3.2) * 0.018
	var stretch: Vector2 = Vector2(1.0 + speed_squash * 0.5 + idle_wobble + wobble_strength * 0.12, 1.0 - speed_squash * 0.32 - idle_wobble * 0.7 - wobble_strength * 0.08)
	if motion_state == MotionState.AIMING and drag_vector.length() > 1.0:
		stretch = Vector2(1.0 + aim_power * 0.38 + idle_wobble, 1.0 - aim_power * 0.22 - idle_wobble)
		draw_set_transform(Vector2.ZERO, drag_vector.angle(), stretch)
	else:
		draw_set_transform(Vector2.ZERO, 0.0, stretch)

	var outline := skin_color.darkened(0.55)
	_draw_jelly_body(Vector2.ZERO, radius, skin_color, outline)
	draw_circle(Vector2(-14.0, -24.0), 15.0, Color(1, 1, 1, 0.92))
	draw_circle(Vector2(14.0, -24.0), 15.0, Color(1, 1, 1, 0.92))

	var look := Vector2.ZERO
	if motion_state == MotionState.AIMING and drag_vector.length() > 1.0:
		look = (-drag_vector).normalized() * 5.0
	elif velocity.length() > 60.0:
		look = velocity.normalized() * 5.0
	var blinking := fmod(blink_timer, 3.4) < 0.09
	if blinking:
		draw_line(Vector2(-26, -24), Vector2(-4, -24), outline, 4.0)
		draw_line(Vector2(4, -24), Vector2(26, -24), outline, 4.0)
	else:
		draw_circle(Vector2(-14, -24) + look, 6.5, Color(0.04, 0.08, 0.09))
		draw_circle(Vector2(14, -24) + look, 6.5, Color(0.04, 0.08, 0.09))

	if face_mood == "hurt":
		draw_line(Vector2(-18, 14), Vector2(18, 6), outline, 4.0)
	elif face_mood == "happy":
		draw_arc(Vector2(0, 4), 24.0, 0.08, PI - 0.08, 24, outline, 5.0)
	else:
		draw_arc(Vector2(0, 8), 17.0, 0.22, PI - 0.22, 18, outline, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_skin_features(outline)

	if motion_state == MotionState.AIMING:
		draw_line(Vector2.ZERO, drag_vector, Color(1, 1, 1, 0.5), 4.0)
		draw_circle(drag_vector, 13.0 + aim_power * 10.0, Color(1, 1, 1, 0.72))
		if assist_touch_index != -1000:
			draw_line(primary_drag_vector, drag_vector, Color(1.0, 0.8, 0.2, 0.75), 6.0)
			draw_circle(drag_vector, 18.0, Color(1.0, 0.8, 0.2, 0.85))


func _draw_jelly_body(center: Vector2, body_radius: float, fill: Color, outline: Color) -> void:
	var points := PackedVector2Array()
	var amp: float = 2.2 + wobble_strength * 7.5
	var stuck: bool = motion_state == MotionState.STICKING and stick_normal.length() > 0.01
	var contact_direction: Vector2 = -stick_normal.normalized() if stuck else Vector2.ZERO
	for index in range(64):
		var angle: float = float(index) / 64.0 * TAU
		var direction := Vector2(cos(angle), sin(angle))
		var wave: float = sin(angle * 5.0 + jelly_time * 7.0) * amp + sin(angle * 3.0 - jelly_time * 4.0) * amp * 0.35
		var r: float = body_radius + wave
		var point: Vector2 = center + direction * r
		if stuck:
			var contact_amount: float = clampf(direction.dot(contact_direction), 0.0, 1.0)
			var back_amount: float = clampf(direction.dot(stick_normal), 0.0, 1.0)
			point += stick_normal * contact_amount * body_radius * 0.22
			point += stick_normal * back_amount * body_radius * 0.08
			point += direction * back_amount * body_radius * 0.06
		points.append(point)
	var outline_points: PackedVector2Array = points.duplicate()
	outline_points.append(points[0])
	draw_colored_polygon(points, fill)
	draw_polyline(outline_points, outline, 5.0)
	if stuck:
		var tangent: Vector2 = Vector2(-contact_direction.y, contact_direction.x)
		var pad_center: Vector2 = center + contact_direction * body_radius * 0.72
		draw_circle(pad_center + tangent * 10.0, body_radius * 0.24, fill.lightened(0.12))
		draw_circle(pad_center - tangent * 12.0, body_radius * 0.2, fill.lightened(0.08))
		draw_line(pad_center - tangent * 18.0, pad_center + tangent * 18.0, Color(1, 1, 1, 0.18), 5.0)
	draw_circle(center + Vector2(-body_radius * 0.22, -body_radius * 0.36), body_radius * 0.22, Color(1, 1, 1, 0.15))
	draw_arc(center + Vector2(-body_radius * 0.14, -body_radius * 0.2), body_radius * 0.62, 3.8, 4.8, 24, Color(1, 1, 1, 0.24), 5.0)
	draw_circle(center + Vector2(-body_radius * 0.42, body_radius * 0.78), body_radius * 0.23, fill.lightened(0.18))
	draw_circle(center + Vector2(body_radius * 0.42, body_radius * 0.78), body_radius * 0.23, fill.lightened(0.18))


func _draw_skin_features(outline: Color) -> void:
	if skin_id == "king":
		var crown := PackedVector2Array([Vector2(-28, -65), Vector2(-16, -95), Vector2(0, -70), Vector2(16, -95), Vector2(28, -65)])
		draw_colored_polygon(crown, Color(1.0, 0.82, 0.18))
		draw_polyline(crown, Color(0.55, 0.34, 0.04), 3.0)
	elif skin_id == "ninja":
		draw_rect(Rect2(Vector2(-34, -36), Vector2(68, 18)), Color(0.02, 0.025, 0.03, 0.82), true)
	elif skin_id == "robot":
		draw_rect(Rect2(Vector2(-38, -8), Vector2(76, 24)), Color(0.76, 0.88, 1.0, 0.5), false, 3.0)
		draw_line(Vector2(-12, 4), Vector2(12, 4), outline, 3.0)
	elif skin_id == "fire":
		draw_colored_polygon(PackedVector2Array([Vector2(34, -62), Vector2(50, -26), Vector2(32, -14), Vector2(18, -30)]), Color(1.0, 0.34, 0.08))
	elif skin_id == "ice":
		draw_arc(Vector2.ZERO, radius * 0.78, -0.35, 1.0, 18, Color(0.86, 1.0, 1.0, 0.75), 4.0)
	elif skin_id == "space":
		draw_circle(Vector2(30, -56), 6.0, Color(1, 1, 1, 0.9))
	elif skin_id == "rainbow":
		draw_arc(Vector2(0, -54), 22.0, PI, TAU, 18, Color(1.0, 0.28, 0.28), 3.0)
		draw_arc(Vector2(0, -54), 27.0, PI, TAU, 18, Color(0.28, 0.82, 1.0), 3.0)
