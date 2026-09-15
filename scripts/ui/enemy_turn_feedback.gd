class_name EnemyTurnFeedback
extends Control

## Replays a completed attack; owns only timing and button recoil.
const DURATION := 0.95
const WINDUP := 0.18
const IMPACT := 0.42
const DANGER := Color("d15a4d")
const BRASS := Color("b9823e")
const AMBER := Color("e0a04a")
var elapsed: float = DURATION
var damage: int = 0
var blocked: int = 0
var source: Vector2
var target: Vector2
var field: Rect2
var button: Control
var play_count: int = 0
var motion_enabled: bool = true
var result_label: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 150
	result_label = Label.new()
	result_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_label.add_theme_font_size_override("font_size", 19)
	result_label.add_theme_color_override("font_shadow_color", Color("0d0e0d"))
	result_label.add_theme_constant_override("shadow_offset_x", 2)
	result_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(result_label)
	visible = false
	set_process(false)

func play_attack(origin: Vector2, destination: Vector2, surface: Rect2, control: Control, hp_damage: int, absorbed: int) -> void:
	cancel()
	source = origin
	target = destination
	field = surface
	button = control
	damage = hp_damage
	blocked = absorbed
	play_count += 1
	if not motion_enabled:
		return
	elapsed = 0.0
	visible = true
	result_label.text = LocalizationManager.translate(&"TURN_HIT", {"damage": damage, "blocked": blocked}) if damage > 0 else LocalizationManager.translate(&"TURN_BLOCKED", {"blocked": blocked})
	result_label.add_theme_color_override("font_color", DANGER if damage > 0 else AMBER)
	result_label.position = Vector2(maxf(18.0, target.x + 34.0), target.y - 20.0)
	result_label.modulate.a = 0.0
	button.pivot_offset = button.size * 0.5
	set_process(true)
	_apply_pose()

func cancel() -> void:
	if is_instance_valid(button):
		button.scale = Vector2.ONE
	elapsed = DURATION
	visible = false
	set_process(false)

func _exit_tree() -> void:
	if is_instance_valid(button):
		button.scale = Vector2.ONE

func _process(delta: float) -> void:
	advance_visuals(delta)

func advance_visuals(delta: float) -> void:
	if not motion_enabled:
		cancel()
		return
	elapsed = minf(DURATION, elapsed + delta)
	if elapsed >= DURATION:
		cancel()
		return
	_apply_pose()
	queue_redraw()

func _apply_pose() -> void:
	if is_instance_valid(button):
		var press := sin(clampf(elapsed / 0.24, 0, 1) * PI)
		button.scale = Vector2.ONE * (1.0 - press * 0.075)
	var arrival := clampf((elapsed - IMPACT) / 0.08, 0, 1)
	var fade := 1.0 - clampf((elapsed - 0.73) / 0.22, 0, 1)
	result_label.modulate.a = arrival * fade
	result_label.position.y = target.y - 20.0 - maxf(0.0, elapsed - IMPACT) * 24.0

func _draw() -> void:
	if elapsed >= DURATION:
		return
	var warning := maxf(0.0, 1.0 - elapsed / 0.34)
	draw_circle(source, 18.0 + elapsed * 16.0, Color(DANGER, warning * 0.16))
	draw_arc(source, 24.0, 0, TAU, 32, Color(DANGER, warning * 0.8), 2.0, true)
	if elapsed >= WINDUP and elapsed <= IMPACT + 0.07:
		var travel := clampf((elapsed - WINDUP) / (IMPACT - WINDUP), 0, 1)
		var point := _path(travel)
		for index in 7:
			var previous := maxf(0.0, travel - float(index + 1) * 0.035)
			draw_line(_path(previous), point, Color(BRASS, 0.28 - float(index) * 0.03), 3.0, true)
		draw_circle(point, 5.0, Color(AMBER, 0.9))
		draw_circle(point, 11.0, Color(AMBER, 0.12))
	if elapsed < IMPACT:
		return
	var time := elapsed - IMPACT
	var strength := maxf(0.0, 1.0 - time / (DURATION - IMPACT))
	var accent := DANGER if damage > 0 else AMBER
	var rail_y := field.position.y + field.size.y * 0.48
	var rail_x := lerpf(field.position.x, field.end.x, clampf(time * 3.0, 0, 1))
	draw_line(Vector2(field.position.x, rail_y), Vector2(rail_x, rail_y), Color(BRASS, strength * 0.18), 2.0, true)
	draw_arc(target, 22.0 + time * 68.0, 0, TAU, 40, Color(accent, strength * 0.85), 3.0, true)
	draw_arc(target, 15.0 + time * 34.0, -2.6, 1.6, 26, Color(AMBER, strength * 0.6), 2.0, true)
	for index in 9:
		var angle := float(index) * 0.69
		var direction := Vector2(cos(angle), sin(angle))
		var point := target + direction * (18.0 + time * 85.0)
		draw_line(point, point + direction * 6.0 * strength, Color(accent, strength), 2.0, true)
	if damage == 0:
		var points := PackedVector2Array([Vector2(-18,-22),Vector2(18,-22),Vector2(16,7),Vector2(0,25),Vector2(-16,7),Vector2(-18,-22)])
		for index in points.size():
			points[index] += target
		draw_colored_polygon(points, Color("171817", strength * 0.9))
		draw_polyline(points, Color(AMBER, strength), 3.0, true)

func _path(progress: float) -> Vector2:
	var point := source.lerp(target, progress)
	point.y += sin(progress * PI) * 60.0
	return point
