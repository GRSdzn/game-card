extends Node

var failures: int = 0
const SEED := "DEAD-BEEF-001"

func _ready() -> void:
	_test_vices()
	_test_intents()
	_test_preview()
	_test_flow()
	_test_replay()
	if failures == 0:
		print("Demo battle tests passed.")
	get_tree().quit(0 if failures == 0 else 1)

func _battle(vice: StringName = &"") -> BattleController:
	RunState.max_hp = 30
	RunState.start_new_run(SEED)
	RunState.weakness_ids.clear()
	if not vice.is_empty():
		RunState.weakness_ids.append(vice)
	var battle := BattleController.new()
	battle.start(RunState.starter_deck, DemoRunController.ENCOUNTER)
	return battle

func _test_vices() -> void:
	var greed := _battle(&"greed")
	greed.player_block = 100
	var forecast := greed.preview_enemy_turn()
	_expect(forecast["hp_loss"] == 5 and forecast["doom_gain"] == 15, "End-turn preview includes Greed despite full block.")
	greed.end_turn()
	_expect(greed.player_hp == 25 and greed.doom == 15, "Greed trades five HP for fifteen Doom even through block.")
	var empty := _battle(&"greed")
	empty.hand.clear()
	empty.player_block = 100
	empty.end_turn()
	_expect(empty.player_hp == 30 and empty.doom == 0, "An empty hand avoids both Greed cost and gain.")
	var lethal := _battle(&"greed")
	lethal.player_hp = 1
	var before_hand := lethal.hand.duplicate()
	var before_rng := RunState.save_rng_state()
	lethal.end_turn()
	_expect(lethal.state == BattleController.State.DEFEAT and lethal.turn_index == 0, "Lethal Vice cost prevents enemy attack and turn advancement.")
	_expect(lethal.hand == before_hand and RunState.save_rng_state() == before_rng, "Lethal cost cannot draw or shuffle.")
	var obsession := _battle(&"obsession")
	_expect(obsession.player_hp == 27, "Obsession charges three HP at battle start.")
	var kick := CardDatabase.get_card(&"grave_kick")
	var guard := CardDatabase.get_card(&"bone_guard")
	var curse := CardDatabase.get_card(&"hangover")
	obsession.hand = [kick, guard, curse]
	obsession.play_card(kick)
	_expect(obsession.doom == 0 and obsession.player_hp == 27, "First card has no suit transition.")
	obsession.play_card(guard)
	_expect(obsession.doom == 3 and obsession.player_hp == 27, "Repeating suit grants Doom.")
	obsession.play_card(curse)
	_expect(obsession.player_hp == 24 and obsession.doom == 7, "Changing suit costs two HP in addition to Hangover's one.")
	obsession.end_turn()
	_expect(obsession.previous_suit == -1, "Suit history resets at next player turn.")
	# Renaming a resource cannot change its behavior: no special-case Vice IDs.
	var renamed := WeaknessDatabase.get_weakness(&"obsession").duplicate() as WeaknessData
	renamed.id = &"arbitrary_test_modifier"
	obsession.weaknesses = [renamed]
	obsession.hand = [kick, guard]
	obsession.play_card(kick)
	var doom_before := obsession.doom
	obsession.play_card(guard)
	_expect(obsession.doom == doom_before + 3, "Vice effects depend on predicates and data, not ID.")

func _test_intents() -> void:
	var battle := _battle()
	_expect(battle.current_intent().id == &"inspection_fee" and battle.current_enemy_damage() == 5, "Opening intent is a five-damage fee.")
	battle.player_block = 2
	battle.end_turn()
	_expect(battle.player_hp == 27 and battle.current_enemy_damage() == 11, "Actual attack respects block and advances to audit.")
	var curse := CardDatabase.get_card(&"hangover")
	battle.hand = [curse, curse]
	battle.play_card(curse)
	battle.score_played_set()
	_expect(battle.current_enemy_damage() == 7, "First ritual reduces audit to seven.")
	battle.play_card(curse)
	battle.score_played_set()
	_expect(battle.current_enemy_damage() == 3 and battle.current_enemy_damage(20) == 3, "Audit reduction has a minimum of three.")
	var hp_before := battle.player_hp
	battle.end_turn()
	_expect(battle.player_hp == hp_before - 3 and battle.current_enemy_damage() == 5 and battle.rituals_this_turn == 0, "Displayed reduced attack matches resolution and resets on next intent.")

func _test_preview() -> void:
	for vice in [&"greed", &"obsession"]:
		var battle := _battle(vice)
		var kick := CardDatabase.get_card(&"grave_kick")
		var curse := CardDatabase.get_card(&"hangover")
		battle.hand = [kick, kick, curse]
		battle.play_card(kick)
		_compare_preview(battle, kick)
		var breaking := battle.preview_ritual(curse)
		_expect(breaking.breaks_combo and not breaking.combo.is_match(), "Adding a curse to a pair warns before breaking the combo.")
		_compare_preview(battle, null, true)
		_compare_preview(battle, curse, true)
	var lethal := _battle(&"obsession")
	lethal.player_hp = 1
	var curse := CardDatabase.get_card(&"hangover")
	lethal.hand = [curse]
	var preview := lethal.preview_ritual(curse)
	_expect(preview.lethal_self_damage and preview.ritual_damage == 0, "Preview never offers ritual damage after a lethal card cost.")
	_compare_preview(lethal, curse, true)
	var locked := _battle()
	locked.energy = 0
	_expect(not locked.preview_ritual(CardDatabase.get_card(&"grave_kick")).playable, "Insufficient energy is rejected by the forecast.")
	_expect(not locked.preview_ritual(CardData.new()).playable, "A card outside the hand cannot be previewed as playable.")
	var direct := _battle()
	direct.enemy_hp = 1
	direct.hand = [CardDatabase.get_card(&"grave_kick")]
	_expect(direct.preview_ritual(direct.hand[0]).card_ends_battle, "A direct kill must be distinguished from sealing a ritual.")
	_compare_preview(direct, direct.hand[0], true)
	# Generic composition: a draw effect followed by a hand-scaled ritual rule.
	var drawing := _battle()
	var draw_card := CardData.new()
	draw_card.tags = [&"curse"]
	var draw_effect := EffectData.new()
	draw_effect.type = EffectData.Type.DRAW
	draw_effect.amount = 2
	draw_card.effects = [draw_effect]
	var rule := WeaknessRule.new()
	rule.trigger = WeaknessData.Trigger.RITUAL_SCORED
	rule.repeat = WeaknessRule.Repeat.CARDS_IN_HAND
	var gain := EffectData.new()
	gain.type = EffectData.Type.GAIN_DOOM
	gain.amount = 1
	rule.effects = [gain]
	var vice := WeaknessData.new()
	vice.rules = [rule]
	drawing.weaknesses = [vice]
	drawing.hand = [draw_card]
	_compare_preview(drawing, draw_card, true)

func _compare_preview(battle: BattleController, card: CardData, seal: bool = false) -> void:
	var before := _snapshot(battle)
	var forecast := battle.preview_ritual(card)
	for _index in 10:
		battle.preview_ritual(card)
	_expect(_snapshot(battle) == before, "Repeated previews cannot mutate battle, run or RNG state.")
	if not seal:
		# Compare the prospective card while leaving its combination unsealed.
		if card != null:
			battle.play_card(card)
		var after := battle.preview_ritual()
		_expect(after.ritual_damage == forecast.ritual_damage and after.combo.id == forecast.combo.id, "Prospective combo equals the actual committed combo.")
		return
	var hp_before := battle.player_hp
	var enemy_before := battle.enemy_hp
	var block_before := battle.player_block
	if card != null:
		battle.play_card(card)
	if battle.can_score_played_set():
		battle.score_played_set()
	_expect(battle.player_hp == hp_before + forecast.hp_delta, "Forecast HP includes Vice costs and ritual triggers.")
	_expect(battle.player_block == block_before + forecast.block_delta, "Forecast block matches actual effects.")
	_expect(battle.enemy_hp == maxi(0, enemy_before - forecast.card_damage - forecast.ritual_damage), "Forecast damage equals actual card + ritual resolution.")
	_expect(battle.doom == forecast.doom_after and battle.multiplier == forecast.multiplier_after, "Forecast post-ritual resources match actual state.")

func _test_flow() -> void:
	var demo := DemoRunController.new()
	demo.begin(SEED)
	_expect(not demo.claim_reward(&"repair") and not demo.continue_shift(), "No reward or continuation before victory.")
	_expect(not demo.choose_vice(&"unknown") and demo.choose_vice(&"greed"), "Only offered Vice IDs can start battle.")
	_expect(not demo.choose_vice(&"obsession"), "Vice selection cannot change during battle.")
	demo.battle.player_hp = 18
	demo.battle.enemy_hp = 1
	var kick := CardDatabase.get_card(&"grave_kick")
	demo.battle.hand = [kick]
	demo.battle.play_card(kick)
	_expect(demo.phase == DemoRunController.Phase.REWARD and RunState.player_hp == 18, "Victory opens compensation and persists health.")
	var terminal := _snapshot(demo.battle)
	demo.battle.end_turn()
	demo.battle.play_card(kick)
	demo.battle.score_played_set()
	_expect(_snapshot(demo.battle) == terminal, "Finished battle rejects all gameplay intents.")
	_expect(not demo.claim_reward(&"unknown"), "Unknown reward is rejected.")
	_expect(demo.claim_reward(&"reinforce") and RunState.max_hp == 34 and RunState.player_hp == 22, "Reinforcement persists max HP and healing.")
	_expect(not demo.claim_reward(&"repair") and RunState.floor_index == 1, "Reward can be claimed exactly once per victory.")
	_expect(demo.continue_shift() and demo.battle.player_hp == 22 and RunState.weakness_ids == [&"greed"], "Next shift carries health and Vice.")
	demo.begin(SEED)
	_expect(RunState.max_hp == 30 and RunState.player_hp == 30 and demo.phase == DemoRunController.Phase.CHOOSING, "New run clears previous upgrades and reopens selection.")
	demo.choose_vice(&"greed")
	demo.battle.player_hp = 1
	demo.battle.end_turn()
	_expect(demo.phase == DemoRunController.Phase.DEFEAT and not demo.claim_reward(&"repair"), "Defeat grants no reward.")
	# Repair uses the same one-claim path and clamps to the current maximum.
	demo.begin(SEED)
	demo.choose_vice(&"greed")
	demo.battle.enemy_hp = 1
	demo.battle.hand = [kick]
	demo.battle.play_card(kick)
	_expect(demo.claim_reward(&"repair") and RunState.player_hp == 30, "Repair cannot over-heal.")

func _test_replay() -> void:
	for vice in DemoRunController.VICE_IDS:
		var first := _replay(vice, false)
		var second := _replay(vice, true)
		_expect(first == second, "Same seed and decisions give identical full state/RNG traces, including with previews.")
		_expect(first.back()["state"] == BattleController.State.VICTORY, "Each Vice has a winning deterministic starter-deck scenario.")
		print("Replay ", vice, ": ", first.size(), " decisions; HP ", first.back()["hp"])

func _replay(vice: StringName, with_previews: bool) -> Array[Dictionary]:
	var battle := _battle(vice)
	var trace: Array[Dictionary] = [_snapshot(battle)]
	for _decision in 60:
		if battle.is_finished():
			break
		if with_previews:
			for card in battle.hand:
				battle.preview_ritual(card)
		if battle.can_score_played_set():
			battle.score_played_set()
		else:
			var next: CardData
			# Fixture policy: seal curses first, then match committed rank.
			for card in battle.hand:
				if not battle.can_play(card):
					continue
				if not battle.played_cards.is_empty() and card.rank == battle.played_cards[0].rank:
					next = card
					break
				if next == null or (battle.played_cards.is_empty() and &"curse" in card.tags):
					next = card
			if next != null:
				battle.play_card(next)
			else:
				battle.end_turn()
		trace.append(_snapshot(battle))
	return trace

func _snapshot(battle: BattleController) -> Dictionary:
	return {"hp": battle.player_hp, "enemy": battle.enemy_hp, "block": battle.player_block,
		"doom": battle.doom, "mult": battle.multiplier, "energy": battle.energy,
		"state": battle.state, "hand": _ids(battle.hand), "draw": _ids(battle.draw_pile),
		"discard": _ids(battle.discard_pile), "played": _ids(battle.played_cards),
		"turn": battle.turn_index, "rituals": battle.rituals_this_turn, "suit": battle.previous_suit,
		"rng": RunState.save_rng_state(), "run_hp": RunState.player_hp, "floor": RunState.floor_index}

func _ids(cards: Array[CardData]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card in cards:
		ids.append(card.id)
	return ids

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
