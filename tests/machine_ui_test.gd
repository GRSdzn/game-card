extends Node

var failures: int = 0

func _ready() -> void:
	for locale in ["en", "ru"]:
		LocalizationManager.set_locale(locale, false)
		for dimensions in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080)]:
			await _test_ui(dimensions)
	if failures == 0:
		print("Machine UI tests passed.")
	get_tree().quit(0 if failures == 0 else 1)

func _test_ui(dimensions: Vector2i) -> void:
	get_window().size = dimensions
	get_tree().root.content_scale_size = dimensions
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	var demo := main.get("demo") as DemoRunController
	var table := main.get("battle_table") as BattleTable
	demo.choose_vice(&"greed")
	await _settle()
	_expect(table.machine_buttons.size() == 2 and not table.machine_buttons[0].disabled, "Active full-pressure battle offers two machine controls.")
	_check_bounds(table)
	await _click(table.machine_buttons[0])
	_expect(demo.battle.energy == 2 and demo.battle.player_block == 4, "Pointer click vents through model intent.")
	_expect(table.machine_buttons[1].disabled and not table.machine_feedback.charged, "Vent locks the alternative and does not charge the ritual.")
	table.machine_buttons[1].pressed.emit()
	_expect(demo.battle.player_hp == 30, "Even an injected disabled-button intent cannot bypass model guards.")
	demo.battle.hand.clear()
	table.end_turn_button.pressed.emit()
	await _settle()
	_expect(not table.machine_buttons[1].disabled, "Next turn offers both modes again.")
	var hp_before := demo.battle.player_hp
	await _click(table.machine_buttons[1])
	_expect(demo.battle.machine_charge and demo.battle.player_hp == hp_before - 3, "Pointer click activates overload and pays HP.")
	_expect(table.machine_feedback.charged and table.pressure_feedback.overpressure, "Charged state drives valve and gauge feedback.")
	var rng_before := RunState.save_rng_state()
	hp_before = demo.battle.player_hp
	for _index in 20:
		table.machine_feedback.advance_visuals(0.1)
		table.pressure_feedback.advance_visuals(0.1)
	_expect(RunState.save_rng_state() == rng_before and demo.battle.player_hp == hp_before, "Warning and steam clocks cannot change gameplay or RNG.")
	var original_locale := LocalizationManager.current_locale
	LocalizationManager.set_locale("ru" if original_locale == "en" else "en", false)
	await _settle()
	_expect(table.machine_feedback.charged and table.machine_status.text == LocalizationManager.translate(&"MACHINE_ARMED"), "Locale rebuild preserves model charge and translates its label.")
	LocalizationManager.set_locale(original_locale, false)
	await _settle()
	get_window().size = Vector2i(1920, 1080) if dimensions.x < 1600 else Vector2i(1280, 720)
	get_tree().root.content_scale_size = get_window().size
	await _settle()
	_expect(table.machine_feedback.charged, "Live resize across layout profiles retains charged feedback.")
	_check_bounds(table)
	get_window().size = dimensions
	get_tree().root.content_scale_size = dimensions
	await _settle()
	_check_bounds(table)
	var curse := CardDatabase.get_card(&"hangover")
	demo.battle.hand = [curse]
	demo.battle.changed.emit()
	table.hand_view.card_views[0].play_requested.emit(curse)
	var damage := demo.battle.preview_ritual().ritual_damage
	_expect(table.ritual_label.text.contains(str(damage)), "Visible ritual damage includes overload.")
	table.score_button.pressed.emit()
	_expect(not table.machine_feedback.charged and table.machine_feedback.discharge_age < 0.7, "Sealing consumes the warning and triggers the discharge.")
	demo.battle.hand.clear()
	table.end_turn_button.pressed.emit()
	demo.battle.player_hp = 3
	demo.battle.changed.emit()
	_expect(table.machine_buttons[1].text.contains(LocalizationManager.translate(&"MACHINE_LETHAL")), "Lethal activation is warned directly on the button.")
	table.machine_buttons[1].pressed.emit()
	_expect(demo.phase == DemoRunController.Phase.DEFEAT and not table.machine_feedback.charged, "Lethal choice opens the normal defeat flow immediately.")
	main.call("_new_run", "MACHINE-UI")
	_expect(not table.machine_feedback.charged and not table.machine_buttons[0].visible, "Restart removes mode controls and warnings while choosing a Vice.")
	main.queue_free()
	await _settle()

func _check_bounds(table: BattleTable) -> void:
	var rect := table.machine_plate.get_global_rect()
	_expect(get_viewport().get_visible_rect().encloses(rect), "Machine plate stays on screen.")
	for button in table.machine_buttons:
		_expect(rect.encloses(button.get_global_rect()), "Both mode buttons stay inside the existing mechanism plate.")
		_expect(button.get_minimum_size().x <= button.size.x and button.get_minimum_size().y <= button.size.y, "Localized two-line buttons fit their geometry.")
	_expect(table.machine_status.get_minimum_size().y <= table.machine_status.size.y, "Machine status fits without clipping.")
	for card in table.hand_view.card_views:
		_expect(not rect.intersects(card.card_frame.get_global_rect()), "Machine controls do not cover hand cards.")
	_expect(not rect.intersects(table.forecast_panel.get_global_rect()), "Machine controls do not cover the forecast.")

func _settle() -> void:
	for _index in 4:
		await get_tree().process_frame

func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion)
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		get_viewport().push_input(click)
		await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
