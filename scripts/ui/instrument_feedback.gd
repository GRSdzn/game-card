class_name InstrumentFeedback
extends Control

## Local, deterministic presentation. No gameplay objects, effects, or RNG.
enum Kind { PRESSURE, PROTECTION }
const BRASS := Color("b9823e")
const AMBER := Color("e0a04a")
const IRON := Color("23221f")
var kind: Kind = Kind.PRESSURE
var needle: Control
var motion_enabled: bool = true:
	set(value):
		motion_enabled = value
		if not value:
			_snap()
		else:
			set_process(active)
var shown_value: float = 0.0
var target_value: float = 0.0
var maximum: float = 3.0
var active: bool = false
var initialized: bool = false
var phase: float = 0.0
var burst_age: float = 2.0
var burst_direction: int = 0
var deployment: float = 0.0
var burst_count: int = 0
var overpressure: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false

func present(value: int, max_value: int, is_active: bool, animate: bool = true) -> void:
	var next := float(maxi(0, value))
	var changed := initialized and not is_equal_approx(next, target_value)
	burst_direction = signi(value - int(target_value)) if changed else burst_direction
	target_value = next
	maximum = maxf(1.0, float(max_value))
	active = is_active
	if not initialized or not animate or not motion_enabled or not active:
		_snap()
	elif changed:
		burst_age = 0.0
		burst_count += 1
	initialized = true
	set_process(motion_enabled and active)
	queue_redraw()

func _process(delta: float) -> void:
	advance_visuals(delta)

func advance_visuals(delta: float) -> void:
	if not motion_enabled or not active:
		return
	phase = fmod(phase + delta, TAU * 10.0)
	burst_age = minf(2.0, burst_age + delta)
	shown_value = lerpf(shown_value, target_value, 1.0 - exp(-delta * 10.0))
	deployment = move_toward(deployment, 1.0 if target_value > 0 else 0.0, delta * 4.0)
	_update_needle()
	queue_redraw()

func _snap() -> void:
	shown_value = target_value
	deployment = 1.0 if target_value > 0 else 0.0
	burst_age = 2.0
	_update_needle()
	set_process(motion_enabled and active)
	queue_redraw()

func _update_needle() -> void:
	if not is_instance_valid(needle):
		return
	var ratio := clampf(shown_value / maximum, 0.0, 1.0)
	var tremor := sin(phase * 5.5) * 0.018 * ratio if motion_enabled and active else 0.0
	if overpressure and motion_enabled and active:
		tremor += sin(phase * 31.0) * 0.055
	var kick := sin(burst_age * 24.0) * exp(-burst_age * 7.0) * 0.13 if burst_age < 1.0 else 0.0
	needle.rotation = lerpf(-1.12, 1.12, ratio) + tremor + kick

func _draw() -> void:
	if kind == Kind.PRESSURE:
		_draw_pressure()
	else:
		_draw_protection()

func _draw_pressure() -> void:
	var center := size * 0.5
	var ratio := clampf(shown_value / maximum, 0.0, 1.0)
	var breathing := 0.06 + 0.035 * sin(phase * 2.2) if motion_enabled and active else 0.06
	draw_arc(center, 37.0, -2.7, -0.45, 28, Color(AMBER, breathing * ratio), 6.0, true)
	# A real-looking outlet: a dark stem and a brass mouth at the gauge edge.
	var outlet := Vector2(size.x - 8.0, 18.0)
	draw_line(outlet + Vector2(-9, 10), outlet, BRASS.darkened(0.3), 5.0, true)
	draw_circle(outlet, 4.0, IRON)
	draw_arc(outlet, 4.0, 0.0, TAU, 16, BRASS, 1.4, true)
	if not motion_enabled or not active:
		return
	var burst := maxf(0.0, 1.0 - burst_age / 0.85)
	for index in 7:
		var age := fmod(phase * (0.48 + ratio * 0.2) + float(index) / 7.0, 1.0)
		var spread := sin(float(index) * 2.4 + age * 3.0)
		var point := outlet + Vector2(age * 22.0 + spread * age * 9.0, -age * (27.0 + 22.0 * burst))
		var opacity := sin(age * PI) * (ratio * 0.07 + burst * 0.24)
		var radius := 2.0 + age * (5.0 + burst * 5.0)
		for layer in 3:
			draw_circle(point, radius * (1.4 - float(layer) * 0.25), Color(0.77, 0.73, 0.62, opacity * 0.33))
	if burst > 0.0:
		draw_arc(center, 42.0, -2.8, 0.1, 32, Color(AMBER, burst * 0.34), 2.0, true)

func _draw_protection() -> void:
	if deployment <= 0.0 and burst_age >= 0.65:
		return
	var pulse := maxf(0.0, 1.0 - burst_age / 0.65)
	var impact := pulse * sin(burst_age * 42.0) * 3.0 if burst_direction < 0 else 0.0
	var slide := (1.0 - deployment) * 15.0
	var alpha := maxf(deployment, pulse * 0.7)
	# Four sliding armour jaws around the HP vessel, never covering its fill.
	for side in [-1.0, 1.0]:
		var x := -7.0 - slide if side < 0 else size.x + 7.0 + slide
		for y in [size.y * 0.23, size.y * 0.70]:
			var plate := Rect2(Vector2(x - 5.0 + impact, y - 15.0), Vector2(10, 30))
			draw_rect(plate, Color(IRON, alpha))
			draw_rect(plate, Color(BRASS, alpha), false, 2.0)
			draw_circle(Vector2(x + impact, y - 8.0), 1.7, Color(BRASS, alpha))
			draw_circle(Vector2(x + impact, y + 8.0), 1.7, Color(BRASS, alpha))
	var center := Vector2(size.x + 26.0 + impact, size.y * 0.48)
	var shield := PackedVector2Array([Vector2(-14,-18), Vector2(14,-18), Vector2(13,6), Vector2(0,19), Vector2(-13,6), Vector2(-14,-18)])
	for index in shield.size():
		shield[index] = center + shield[index] * (0.8 + deployment * 0.2)
	draw_colored_polygon(shield, Color(IRON, alpha))
	draw_polyline(shield, Color(BRASS.lerp(AMBER, pulse), alpha), 2.2, true)
	draw_line(center + Vector2(0,-10), center + Vector2(0,9), Color(BRASS, alpha * 0.6), 2.0, true)
	if pulse > 0.0:
		draw_arc(center, 22.0 + burst_age * 22.0, 0, TAU, 32, Color(AMBER, pulse * 0.4), 1.5, true)
		if burst_direction < 0:
			for index in 5:
				var angle := float(index) * 1.25
				var direction := Vector2(cos(angle), sin(angle))
				var point := center + direction * (18.0 + burst_age * 40.0)
				draw_line(point, point + direction * 4.0, Color(AMBER, pulse), 1.5, true)
