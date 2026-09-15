class_name MachineFeedback
extends Control

## A local valve and charge ring. Presentation time never drives battle rules.
var available: bool = false
var charged: bool = false
var phase: float = 0.0
var discharge_age: float = 1.0
var motion_enabled: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func present(can_choose: bool, is_charged: bool) -> void:
	available = can_choose
	charged = is_charged
	set_process(motion_enabled and (available or charged or discharge_age < 0.7))
	queue_redraw()

func discharge() -> void:
	discharge_age = 0.0 if motion_enabled else 1.0
	set_process(motion_enabled)
	queue_redraw()

func cancel() -> void:
	available = false
	charged = false
	discharge_age = 1.0
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	advance_visuals(delta)

func advance_visuals(delta: float) -> void:
	if not motion_enabled:
		set_process(false)
		return
	phase = fmod(phase + delta, TAU * 10.0)
	discharge_age = minf(1.0, discharge_age + delta)
	set_process(available or charged or discharge_age < 0.7)
	queue_redraw()

func _draw() -> void:
	if not available and not charged and discharge_age >= 0.7:
		return
	var center := size * 0.5
	var radius := size.x * 0.44
	var tremor := sin(phase * 32.0) * (1.8 if charged else 0.7) if motion_enabled else 0.0
	var pulse := 0.65 + sin(phase * 4.0) * 0.18 if motion_enabled else 0.75
	var brass := Color("b9823e")
	var accent := Color("d15a4d") if charged else Color("e0a04a")
	var valve := center + Vector2(-radius, tremor)
	draw_circle(valve, 12.0, Color("171817"))
	draw_arc(valve, 11.0, 0.0, TAU, 20, brass, 3.0, true)
	draw_line(valve + Vector2(-8, -tremor), valve + Vector2(8, tremor), brass, 3.0, true)
	draw_line(valve + Vector2(0, -8), valve + Vector2(0, 8), brass, 3.0, true)
	draw_circle(center + Vector2(0, -radius - 8), 4.0, Color(accent, pulse))
	if charged:
		for index in 4:
			var angle := float(index) * PI * 0.5 + 0.2
			draw_arc(center, radius - 7, angle, angle + 0.75, 16, Color(accent, pulse * 0.55), 2.0, true)
		if motion_enabled:
			for index in 5:
				var age := fmod(phase * 0.8 + float(index) / 5.0, 1.0)
				var point := valve + Vector2(-age * 20, -12 - age * 25)
				draw_circle(point, 2 + age * 6, Color(0.77, 0.73, 0.62, sin(age * PI) * 0.13))
	if discharge_age < 0.7:
		var fade := 1.0 - discharge_age / 0.7
		draw_arc(center, radius + discharge_age * 18, 0, TAU, 64, Color("e0a04a", fade * 0.7), 3.0, true)
		for side in [-1.0, 1.0]:
			for index in 5:
				var point := center + Vector2(side * (radius + discharge_age * 40), float(index - 2) * 6 - discharge_age * 16)
				draw_circle(point, 3 + discharge_age * 8, Color(0.77, 0.73, 0.62, fade * 0.12))
