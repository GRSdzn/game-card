extends Node

var failures: int = 0

func _ready() -> void:
	LocalizationManager.set_locale("en", false)
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var demo := main.get("demo") as DemoRunController
	demo.choose_vice(&"greed")
	var table := main.get("battle_table") as BattleTable
	var steam := table.pressure_feedback
	var shield := table.protection_feedback
	steam.set_process(false)
	shield.set_process(false)
	var rng_before := RunState.save_rng_state()
	var hp_before := demo.battle.player_hp
	var guard := CardDatabase.get_card(&"bone_guard")
	demo.battle.hand = [guard, guard]
	demo.battle.play_card(guard)
	_expect(demo.battle.energy == 2 and demo.battle.player_block == 5, "Gameplay updates immediately before animation.")
	_expect(steam.target_value == 2 and shield.target_value == 5, "Table mirrors pressure and protection changes.")
	_expect(steam.shown_value > steam.target_value and shield.deployment == 0, "Motion begins from the previous visual state.")
	_expect(steam.burst_direction == -1 and shield.burst_direction == 1, "Spend and deployment use distinct feedback directions.")
	var bursts := steam.burst_count
	main.call("_refresh")
	_expect(steam.burst_count == bursts, "Repeated state snapshots cannot replay the burst.")
	for _frame in 12:
		steam.advance_visuals(1.0 / 60.0)
		shield.advance_visuals(1.0 / 60.0)
	_expect(steam.shown_value > 2 and steam.shown_value < 3 and shield.deployment > 0.7, "Needle and armour move through intermediate positions.")
	demo.battle.play_card(guard)
	_expect(steam.target_value == 1 and shield.target_value == 10, "Rapid plays retarget the existing effect without stale completion callbacks.")
	for _frame in 120:
		steam.advance_visuals(1.0 / 60.0)
		shield.advance_visuals(1.0 / 60.0)
	_expect(absf(steam.shown_value - 1) < 0.001 and shield.deployment == 1, "Effects settle to the latest snapshot.")
	_expect(RunState.save_rng_state() == rng_before and demo.battle.player_hp == hp_before, "Visual ticks cannot consume gameplay RNG or health.")
	demo.battle.end_turn()
	_expect(steam.burst_direction == 1 and shield.burst_direction == -1, "Refill and lost protection animate in opposite directions.")
	_expect(demo.battle.player_hp == hp_before and demo.battle.player_block == 0, "Protection blocks the attack independently of its visual collapse.")
	steam.motion_enabled = false
	shield.motion_enabled = false
	_expect(steam.shown_value == 3 and shield.deployment == 0 and not steam.is_processing(), "Disabled motion snaps to a readable static state.")
	steam.motion_enabled = true
	_expect(steam.is_processing(), "Re-enabling motion resumes local processing.")
	LocalizationManager.set_locale("ru", false)
	await get_tree().process_frame
	_expect(table.pressure_feedback.burst_count == 0, "Locale rebuild starts at the current value without a false burst.")
	table.pressure_feedback.present(0, 3, false)
	_expect(not table.pressure_feedback.is_processing(), "Inactive battle stops background instrument processing.")
	main.queue_free()
	await get_tree().process_frame
	if failures == 0:
		print("Instrument feedback tests passed.")
	get_tree().quit(0 if failures == 0 else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
