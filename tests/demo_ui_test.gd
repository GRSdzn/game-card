extends Node

const MAIN := preload("res://scenes/main.tscn")
var failures: int = 0

func _ready() -> void:
	for locale in ["en", "ru"]:
		LocalizationManager.set_locale(locale, false)
		for dimensions in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080)]:
			await _test_flow(dimensions)
	if failures == 0:
		print("Demo UI tests passed.")
	get_tree().quit(0 if failures == 0 else 1)

func _test_flow(dimensions: Vector2i) -> void:
	get_window().size = dimensions
	get_tree().root.content_scale_size = dimensions
	var main := MAIN.instantiate()
	add_child(main)
	await _settle()
	var flow := main.get("flow_view") as DemoFlowView
	var table := main.get("battle_table") as BattleTable
	var demo := main.get("demo") as DemoRunController
	_expect(flow.visible and flow.choice_buttons.size() == 2, "Initial screen has exactly two Vice choices.")
	_expect(flow.z_index > 100, "Choice tray must render above raised cards and table slots.")
	_expect(demo.battle.state == BattleController.State.INACTIVE and table.end_turn_button.disabled, "Battle input is locked until a Vice is chosen.")
	_check_bounds(flow, dimensions)
	await _click(flow.choice_buttons[1])
	await _settle()
	_expect(not flow.visible and demo.selected_vice == &"obsession", "Choice button starts selected Vice through model intent.")
	_expect(table.enemy_label.text.contains("5") and table.enemy_label.text.contains("48"), "Live Inspector displays actual intent and maximum HP.")
	var before_rng := RunState.save_rng_state()
	var hp_before := demo.battle.player_hp
	var hand_before := demo.battle.hand.duplicate()
	var view := table.hand_view.card_views[0]
	view._on_mouse_entered()
	await _settle()
	_expect(table.forecast_label.text.begins_with(view.card_data.get_title()), "Hover routes through CardView/HandView/Table to a model forecast.")
	_expect(RunState.save_rng_state() == before_rng and demo.battle.player_hp == hp_before and demo.battle.hand == hand_before, "UI hover is read-only.")
	var card_top := INF
	for hand_card in table.hand_view.card_views:
		card_top = minf(card_top, hand_card.card_frame.get_global_rect().position.y)
	_expect(table.forecast_panel.get_global_rect().end.y < card_top, "Forecast clears the visible hand cards.")
	_expect(table.forecast_label.get_minimum_size().y <= table.forecast_label.size.y, "Forecast text fits its mechanical plate.")
	for hand_card in table.hand_view.card_views:
		hand_card._on_mouse_entered()
		await _settle()
		_expect(table.forecast_panel.get_global_rect().encloses(table.forecast_label.get_global_rect()), "Every card forecast stays inside its plate.")
		hand_card._on_mouse_exited()
	view._on_mouse_exited()
	_expect(table.forecast_label.text.begins_with(LocalizationManager.translate(&"PREVIEW_NOW")), "Leaving a card restores the current ritual forecast.")
	# Live localization rebuild must retain the actual model-derived intent.
	var locale_before := LocalizationManager.current_locale
	LocalizationManager.set_locale("ru" if locale_before == "en" else "en", false)
	await _settle()
	_expect(table.enemy_label.text.contains(LocalizationManager.translate(&"INTENT_FEE")), "Locale switch retains dynamic intent.")
	LocalizationManager.set_locale(locale_before, false)
	await _settle()
	table.end_turn_button.pressed.emit()
	await _settle()
	_expect(demo.battle.current_enemy_damage() == 11 and table.enemy_label.text.contains("11"), "Enemy turn button advances to telegraphed audit.")
	# Fixed one-hit fixture exercises real victory signal -> reward UI.
	demo.battle.enemy_hp = 1
	demo.battle.hand = [CardDatabase.get_card(&"grave_kick")]
	demo.battle.changed.emit()
	await _settle()
	view = table.hand_view.card_views[0]
	view.play_requested.emit(view.card_data)
	await _settle()
	_expect(flow.visible and demo.phase == DemoRunController.Phase.REWARD and flow.choice_buttons.size() == 2, "Victory reveals a single reward selection.")
	_expect(table.score_button.disabled and table.end_turn_button.disabled, "Reward screen locks combat.")
	_check_bounds(flow, dimensions)
	flow.choice_buttons[1].pressed.emit()
	await _settle()
	_expect(demo.phase == DemoRunController.Phase.COMPLETE and RunState.max_hp == 34, "Reward button applies model reward once.")
	_check_bounds(flow, dimensions)
	flow.choice_buttons[0].pressed.emit()
	await _settle()
	_expect(demo.phase == DemoRunController.Phase.BATTLE and not flow.visible, "Continue button opens next shift.")
	table.new_run_requested.emit("DEMO-UI-RESTART")
	await _settle()
	_expect(flow.visible and RunState.max_hp == 30 and RunState.seed_text == "DEMO-UI-RESTART", "Archive restart resets the run and returns to choice.")
	flow.choice_buttons[0].pressed.emit()
	await _settle()
	demo.battle.player_hp = 1
	table.end_turn_button.pressed.emit()
	await _settle()
	_expect(demo.phase == DemoRunController.Phase.DEFEAT and flow.choice_buttons.size() == 1, "Defeat screen offers restart only.")
	flow.choice_buttons[0].pressed.emit()
	await _settle()
	_expect(demo.phase == DemoRunController.Phase.CHOOSING, "Defeat restart reaches Vice selection.")
	main.queue_free()
	await _settle()

func _check_bounds(flow: DemoFlowView, dimensions: Vector2i) -> void:
	var rect := flow.tray.get_global_rect()
	_expect(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(rect), "Document tray stays inside viewport.")
	for node in flow.choices_box.get_children():
		_expect(rect.encloses(node.get_global_rect()), "Reward/Vice buttons and descriptions remain inside tray.")
		if node is Label:
			_expect(node.get_minimum_size().y <= node.size.y, "Choice description is not vertically clipped.")

func _settle() -> void:
	for _index in 3:
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
