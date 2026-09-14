extends Node

const TEST_SEED := "BATTLE-SMOKE-001"

func _ready() -> void:
	get_tree().quit(0 if _run() else 1)

func _run() -> bool:
	if not _test_combo_evaluator():
		return false
	RunState.start_new_run(TEST_SEED)
	var first_battle := BattleController.new()
	first_battle.start(RunState.starter_deck)
	var first_hand := _card_ids(first_battle.hand)

	RunState.start_new_run(TEST_SEED)
	var second_battle := BattleController.new()
	second_battle.start(RunState.starter_deck)
	if not _expect(_card_ids(second_battle.hand) == first_hand, "A seed must produce the same opening hand."):
		return false

	var lethal_battle := BattleController.new()
	RunState.start_new_run(TEST_SEED)
	lethal_battle.start(RunState.starter_deck)
	lethal_battle.player_hp = 1
	lethal_battle.enemy_damage = 1
	var hand_before_defeat := _card_ids(lethal_battle.hand)
	lethal_battle.end_turn()
	if not _expect(lethal_battle.is_finished(), "Lethal enemy damage must finish the battle."):
		return false
	if not _expect(not lethal_battle.victory, "A dead player must lose the battle."):
		return false
	if not _expect(_card_ids(lethal_battle.hand) == hand_before_defeat, "A finished battle must not discard or draw cards."):
		return false
	if not _expect(RunState.player_hp == 0, "RunState must retain defeat HP."):
		return false
	if not _test_enemy_turn_weakness():
		return false
	if not _test_curse_combo_damage():
		return false

	print("Battle smoke tests passed.")
	return true

func _test_combo_evaluator() -> bool:
	var pair := ComboEvaluator.evaluate([
		_card(&"pair_a", 4, CardData.Suit.BONE, []),
		_card(&"pair_b", 4, CardData.Suit.BLOOD, []),
	])
	if not _expect(pair.id == &"pair" and pair.base_doom == 2 and pair.multiplier == 1, "Pair must be evaluated deterministically."):
		return false
	if not _expect(pair.matched_card_ids == [&"pair_a", &"pair_b"], "Pair must preserve card ID order."):
		return false

	var triple_cards: Array[CardData] = []
	for index in 3:
		triple_cards.append(_card(&"triple_%d" % index, 7, CardData.Suit.FLESH, []))
	if not _expect(ComboEvaluator.evaluate(triple_cards).id == &"triple", "Triple must require three equal ranks."):
		return false

	var procession_cards: Array[CardData] = []
	for index in 5:
		procession_cards.append(_card(&"procession_%d" % index, index + 1, CardData.Suit.SPIRIT, []))
	var procession := ComboEvaluator.evaluate(procession_cards)
	if not _expect(procession.id == &"procession" and procession.multiplier == 2, "Procession must require five equal suits."):
		return false

	var black_mass := ComboEvaluator.evaluate([_card(&"curse", 1, CardData.Suit.GOLD, [&"curse"])])
	if not _expect(black_mass.id == &"black_mass", "A curse-only set must form Black Mass."):
		return false
	return _expect(not ComboEvaluator.evaluate([_card(&"none", 1, CardData.Suit.BONE, [])]).is_match(), "Unmatched cards must not score.")

func _test_curse_combo_damage() -> bool:
	RunState.start_new_run(TEST_SEED)
	var battle := BattleController.new()
	battle.start(RunState.starter_deck)
	var hangover := CardDatabase.get_card(&"hangover")
	battle.hand.clear()
	battle.draw_pile.clear()
	battle.discard_pile.clear()
	battle.hand.append(hangover)
	battle.play_card(hangover)
	battle.score_played_set()
	return _expect(
		battle.enemy_hp == 12 and battle.player_hp == 29 and battle.doom == 0 and battle.last_combo.id == &"black_mass",
		"Black Mass must convert Hangover's stored doom into ritual damage."
	)

func _test_enemy_turn_weakness() -> bool:
	RunState.start_new_run(TEST_SEED)
	RunState.weakness_ids = [&"late_fee"]
	var battle := BattleController.new()
	battle.start(RunState.starter_deck)
	battle.enemy_damage = 0
	battle.end_turn()
	return _expect(
		battle.player_hp == 29 and battle.weakness_names() == WeaknessDatabase.get_weakness(&"late_fee").get_title(),
		"An enemy-turn weakness must resolve through its data-driven trigger."
	)

func _card(id: StringName, rank: int, suit: CardData.Suit, tags: Array[StringName]) -> CardData:
	var card := CardData.new()
	card.id = id
	card.rank = rank
	card.suit = suit
	card.tags = tags
	return card

func _card_ids(cards: Array[CardData]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card in cards:
		ids.append(card.id)
	return ids

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition
