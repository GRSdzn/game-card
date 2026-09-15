extends Node

var failures: int = 0
var results: Array[Vector2i] = []

func _ready() -> void:
	LocalizationManager.set_locale("en", false)
	var main := preload("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	var demo := main.get("demo") as DemoRunController
	var table := main.get("battle_table") as BattleTable
	demo.battle.enemy_attack_resolved.connect(func(damage: int, blocked: int) -> void: results.append(Vector2i(damage, blocked)))
	table.end_turn_requested.emit()
	_expect(results.is_empty(), "Inactive battles emit no attack or animation.")
	demo.choose_vice(&"greed")
	demo.battle.hand.clear()
	demo.battle.player_block = 8
	main.call("_refresh")
	table.end_turn_button.pressed.emit()
	var feedback := table.enemy_turn_feedback
	feedback.set_process(false)
	_expect(results == [Vector2i(0, 5)], "Signal reports actual absorbed damage, not expired excess block.")
	_expect(feedback.visible and feedback.damage == 0 and feedback.blocked == 5, "Actual button intent launches the blocked sequence.")
	_expect(demo.battle.turn_index == 1 and demo.battle.player_block == 0, "Full next-turn state is resolved before animation finishes.")
	var rng_before := RunState.save_rng_state()
	var hp_before := demo.battle.player_hp
	var hand_before := demo.battle.hand.duplicate()
	feedback.advance_visuals(0.12)
	_expect(table.end_turn_button.scale.x < 1, "Mechanical button recoils during wind-up.")
	feedback.advance_visuals(0.40)
	_expect(feedback.result_label.modulate.a > 0.9 and "BLOCKED" in feedback.result_label.text, "Contact stage shows the blocked result.")
	feedback.advance_visuals(0.5)
	_expect(not feedback.visible and table.end_turn_button.scale == Vector2.ONE, "Sequence cleans up and restores button geometry.")
	_expect(RunState.save_rng_state() == rng_before and demo.battle.player_hp == hp_before and demo.battle.hand == hand_before, "Visual timeline never changes battle or RNG.")
	demo.battle.hand.clear()
	demo.battle.player_block = 3
	table.end_turn_button.pressed.emit()
	_expect(results.back() == Vector2i(8, 3) and feedback.damage == 8, "Partial protection reports remaining HP damage.")
	var count := feedback.play_count
	main.call("_refresh")
	_expect(feedback.play_count == count, "State refresh cannot replay an attack event.")
	feedback.advance_visuals(0.1)
	demo.battle.hand.clear()
	table.end_turn_button.pressed.emit()
	_expect(feedback.play_count == count + 1 and feedback.elapsed == 0, "Rapid valid turns replace the previous cosmetic sequence safely.")
	feedback.motion_enabled = false
	feedback.advance_visuals(0.1)
	_expect(not feedback.visible and table.end_turn_button.scale == Vector2.ONE, "Motion fallback restores controls without blocking turns.")
	LocalizationManager.set_locale("ru", false)
	await get_tree().process_frame
	_expect(not table.enemy_turn_feedback.visible, "Locale rebuild cancels obsolete effects.")
	main.call("_new_run", "ENEMY-ANIMATION-LETHAL")
	demo.choose_vice(&"greed")
	demo.battle.player_hp = 1
	var previous_results := results.size()
	table.end_turn_button.pressed.emit()
	_expect(results.size() == previous_results and not table.enemy_turn_feedback.visible, "Lethal Vice cost does not invent an enemy attack.")
	main.call("_new_run", "ENEMY-ANIMATION-HIT")
	demo.choose_vice(&"greed")
	demo.battle.hand.clear()
	demo.battle.player_hp = 1
	table.end_turn_button.pressed.emit()
	_expect(results.size() == previous_results + 1 and demo.battle.is_finished(), "A lethal enemy attack still emits exactly one result.")
	main.call("_new_run", "ENEMY-ANIMATION-RESET")
	_expect(not table.enemy_turn_feedback.visible and table.end_turn_button.scale == Vector2.ONE, "Restart clears ongoing attack feedback.")
	main.queue_free()
	await get_tree().process_frame
	if failures == 0:
		print("Enemy turn feedback tests passed.")
	get_tree().quit(0 if failures == 0 else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
