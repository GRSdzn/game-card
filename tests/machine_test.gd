extends Node

var failures: int = 0

func _ready() -> void:
	_test_choices()
	_test_ritual()
	_test_guards()
	_expect(_replay(false) == _replay(true), "Seeded machine decisions and RNG trace match with repeated forecasts.")
	if failures == 0:
		print("Machine tests passed.")
	get_tree().quit(0 if failures == 0 else 1)

func _battle() -> BattleController:
	RunState.max_hp = 30
	RunState.start_new_run("MACHINE-TEST")
	RunState.weakness_ids.clear()
	var battle := BattleController.new()
	battle.start(RunState.starter_deck, DemoRunController.ENCOUNTER)
	return battle

func _test_choices() -> void:
	var battle := _battle()
	var before_rng := RunState.save_rng_state()
	_expect(not battle.choose_machine_mode(&"unknown"), "Unknown mode has no effect.")
	_expect(battle.energy == 3 and battle.machine_mode == null, "Invalid choice cannot spend pressure or the turn slot.")
	_expect(battle.choose_machine_mode(&"vent"), "Full pressure can be vented.")
	_expect(battle.energy == 2 and battle.player_block == 4 and battle.player_hp == 30, "Vent trades one pressure for four block.")
	_expect(not battle.machine_charge and not battle.choose_machine_mode(&"overload"), "Modes are mutually exclusive this turn.")
	battle.energy = 3
	_expect(not battle.choose_machine_mode(&"vent"), "Restoring pressure does not bypass once-per-turn guard.")
	_expect(RunState.save_rng_state() == before_rng, "Modes do not consume gameplay randomness.")
	battle.end_turn()
	_expect(battle.can_choose_machine_mode() and battle.machine_mode == null, "Next turn restores choice availability.")
	battle.player_block = 100
	var hp_before := battle.player_hp
	_expect(battle.choose_machine_mode(&"overload"), "Overload arms at full pressure.")
	_expect(battle.player_hp == hp_before - 3 and battle.player_block == 100 and battle.energy == 2, "Arming pays exactly three HP through block and one pressure.")
	_expect(battle.machine_charge, "Arming reserves the next ritual bonus.")
	battle.end_turn()
	_expect(not battle.machine_charge and battle.machine_mode == null, "Unused bonus expires at end turn.")

func _test_ritual() -> void:
	var battle := _battle()
	var curse := CardDatabase.get_card(&"hangover")
	battle.hand = [curse, curse]
	battle.choose_machine_mode(&"overload")
	battle.score_played_set()
	_expect(battle.machine_charge, "Invalid ritual does not consume charge.")
	var before := _snapshot(battle)
	var forecast := battle.preview_ritual(curse)
	for _index in 12:
		battle.preview_ritual(curse)
		battle.preview_machine_mode(BattleController.MACHINE_MODES[1])
	_expect(_snapshot(battle) == before, "All machine/ritual forecasts are pure.")
	_expect(forecast.ritual_damage == 20 and forecast.machine_bonus == 8, "Flat eight damage is added after the curse ritual multiplier.")
	var hp_before := battle.player_hp
	var enemy_before := battle.enemy_hp
	battle.play_card(curse)
	battle.score_played_set()
	_expect(battle.enemy_hp == enemy_before - forecast.ritual_damage and battle.player_hp == hp_before + forecast.hp_delta, "Armed prospective forecast matches actual resolution.")
	_expect(not battle.machine_charge and battle.machine_mode != null, "Successful seal consumes charge but retains the turn lock.")
	var second := battle.preview_ritual(curse)
	_expect(second.machine_bonus == 0 and second.ritual_damage == 12, "Second ritual receives no duplicate bonus.")
	battle.play_card(curse)
	battle.score_played_set()
	_expect(battle.enemy_hp == 16, "Two curse rituals deal twenty then twelve damage.")
	# Renamed resource and changed payload prove resolution does not branch on ID.
	battle = _battle()
	var mode := BattleController.MACHINE_MODES[1].duplicate(true) as MachineModeData
	mode.id = &"arbitrary_machine"
	mode.ritual_effects[0].amount = 5
	battle.machine_mode = mode
	battle.machine_charge = true
	battle.hand = [curse]
	_expect(battle.preview_ritual(curse).ritual_damage == 17, "Forecast reads the resource payload rather than an overload ID.")
	battle.play_card(curse)
	battle.score_played_set()
	_expect(battle.enemy_hp == 31, "Renamed machine mode resolves its data through the effect system.")

func _test_guards() -> void:
	var inactive := BattleController.new()
	_expect(not inactive.choose_machine_mode(&"overload") and inactive.machine_mode == null, "Inactive model rejects machine activation.")
	var battle := _battle()
	battle.energy = 2
	_expect(not battle.choose_machine_mode(&"overload") and battle.player_hp == 30, "Partially spent pressure rejects choices without paying HP.")
	battle.energy = 3
	battle.player_hp = 3
	battle.player_block = 100
	var preview := battle.preview_machine_mode(BattleController.MACHINE_MODES[1])
	_expect(preview["lethal"] and preview["hp_loss"] == 3, "Three HP correctly forecasts a lethal activation through armour.")
	var rng_before := RunState.save_rng_state()
	battle.choose_machine_mode(&"overload")
	_expect(battle.state == BattleController.State.DEFEAT and not battle.machine_charge, "Lethal arming resolves defeat immediately without a lingering charge.")
	var before := _snapshot(battle)
	_expect(not battle.choose_machine_mode(&"vent"), "Defeated model rejects machine input.")
	battle.score_played_set()
	_expect(_snapshot(battle) == before and RunState.save_rng_state() == rng_before, "Terminal input cannot change state or RNG.")
	battle = _battle()
	battle.choose_machine_mode(&"overload")
	battle.enemy_hp = 1
	var kick := CardDatabase.get_card(&"grave_kick")
	battle.hand = [kick]
	_expect(battle.preview_ritual(kick).ritual_damage == 0, "Direct card kill does not forecast an extra ritual.")
	battle.play_card(kick)
	_expect(not battle.choose_machine_mode(&"vent") and not battle.machine_charge, "Victory clears charge and rejects mode input.")
	var demo := DemoRunController.new()
	demo.begin("MACHINE-RESTART")
	demo.choose_vice(&"greed")
	demo.battle.choose_machine_mode(&"overload")
	demo.begin("MACHINE-RESTART")
	_expect(demo.battle.machine_mode == null and not demo.battle.machine_charge, "New run clears both machine fields even on the choice screen.")

func _replay(with_previews: bool) -> Array[Dictionary]:
	var battle := _battle()
	var trace: Array[Dictionary] = []
	for _turn in 3:
		if battle.is_finished():
			break
		battle.choose_machine_mode(&"overload")
		for card in battle.hand.duplicate():
			if with_previews:
				battle.preview_ritual(card)
				battle.preview_enemy_turn()
			battle.play_card(card)
			if battle.can_score_played_set():
				battle.score_played_set()
			trace.append(_snapshot(battle))
		battle.end_turn()
		trace.append(_snapshot(battle))
	return trace

func _snapshot(battle: BattleController) -> Dictionary:
	return {"hp": battle.player_hp, "enemy": battle.enemy_hp, "block": battle.player_block,
		"energy": battle.energy, "doom": battle.doom, "state": battle.state,
		"mode": battle.machine_mode.id if battle.machine_mode != null else &"",
		"charge": battle.machine_charge, "hand": battle.hand.duplicate(),
		"draw": battle.draw_pile.duplicate(), "discard": battle.discard_pile.duplicate(),
		"committed": battle.played_cards.duplicate(), "rng": RunState.save_rng_state()}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
