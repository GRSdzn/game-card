class_name BattleController
extends RefCounted

signal changed
signal battle_finished(victory: bool)
signal log_added(message: LocalizedMessage)

const HAND_SIZE := 5
const MAX_ENERGY := 3

enum State { INACTIVE, ACTIVE, VICTORY, DEFEAT }

var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = []
var played_cards: Array[CardData] = []
var weaknesses: Array[WeaknessData] = []
var energy: int = MAX_ENERGY
var player_hp: int = 30
var player_block: int = 0
var enemy_hp: int = 24
var enemy_damage: int = 6
var doom: int = 0
var multiplier: int = 1
var state: State = State.INACTIVE
var victory: bool = false
var last_combo: ComboResult = ComboResult.new()

func start(deck_ids: Array[StringName]) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	played_cards.clear()
	weaknesses.clear()
	energy = MAX_ENERGY
	player_hp = RunState.player_hp
	player_block = 0
	enemy_hp = 24
	doom = 0
	multiplier = 1
	state = State.ACTIVE
	victory = false
	last_combo = ComboResult.new()
	for id in deck_ids:
		var card := CardDatabase.get_card(id)
		if card != null:
			draw_pile.append(card)
		else:
			push_error("BattleController: missing card ID '%s' in deck." % id)
	for id in RunState.weakness_ids:
		var weakness := WeaknessDatabase.get_weakness(id)
		if weakness != null:
			weaknesses.append(weakness)
		else:
			push_error("BattleController: missing weakness ID '%s' in run." % id)
	_shuffle_with_run_rng(draw_pile)
	draw(HAND_SIZE)
	_log(LocalizedMessage.template(&"LOG_BATTLE_STARTED"))
	_trigger_weaknesses(WeaknessData.Trigger.BATTLE_STARTED)
	_check_finished()
	changed.emit()

func can_play(card: CardData) -> bool:
	return state == State.ACTIVE and card != null and card in hand and card.cost <= energy

func can_score_played_set() -> bool:
	return state == State.ACTIVE and ComboEvaluator.evaluate(played_cards).is_match()

func weakness_names() -> String:
	if weaknesses.is_empty():
		return "None"
	var names: PackedStringArray = []
	for weakness in weaknesses:
		names.append(weakness.get_title())
	return ", ".join(names)

func play_card(card: CardData) -> void:
	if not can_play(card):
		return
	energy -= card.cost
	var context := EffectContext.new(player_hp, player_block, enemy_hp, doom, multiplier)
	for effect in card.effects:
		EffectResolver.resolve(effect, context)
	_apply_context(context)
	hand.erase(card)
	discard_pile.append(card)
	played_cards.append(card)
	_log(LocalizedMessage.card_played(card))
	_trigger_weaknesses(WeaknessData.Trigger.CARD_PLAYED)
	if _check_finished():
		changed.emit()
		return
	if context.draw_requested > 0:
		draw(context.draw_requested)
	changed.emit()

func score_played_set() -> void:
	if state != State.ACTIVE:
		return
	var combo := ComboEvaluator.evaluate(played_cards)
	if not combo.is_match():
		_log(LocalizedMessage.template(&"LOG_NO_COMBINATION"))
		changed.emit()
		return
	last_combo = combo
	doom += combo.base_doom
	var damage: int = doom * multiplier * combo.multiplier
	enemy_hp = maxi(0, enemy_hp - damage)
	_log(LocalizedMessage.combo_damage(combo, damage))
	doom = 0
	played_cards.clear()
	_trigger_weaknesses(WeaknessData.Trigger.RITUAL_SCORED)
	_check_finished()
	changed.emit()

func end_turn() -> void:
	if state != State.ACTIVE:
		return
	if not played_cards.is_empty():
		_log(LocalizedMessage.template(&"LOG_UNSCORED_CARDS"))
		played_cards.clear()
	_trigger_weaknesses(WeaknessData.Trigger.ENEMY_TURN_STARTED)
	if _check_finished():
		changed.emit()
		return
	var damage: int = maxi(0, enemy_damage - player_block)
	player_hp = maxi(0, player_hp - damage)
	player_block = 0
	_log(LocalizedMessage.template(&"LOG_ENEMY_DAMAGE", {"damage": damage}))
	if _check_finished():
		changed.emit()
		return
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	energy = MAX_ENERGY
	draw(HAND_SIZE)
	changed.emit()

func draw(count: int) -> void:
	for _index in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			_shuffle_with_run_rng(draw_pile)
		hand.append(draw_pile.pop_back())

func is_finished() -> bool:
	return state == State.VICTORY or state == State.DEFEAT

func _trigger_weaknesses(trigger: WeaknessData.Trigger) -> void:
	var context := EffectContext.new(player_hp, player_block, enemy_hp, doom, multiplier)
	for weakness in weaknesses:
		if weakness.trigger != trigger:
			continue
		for effect in weakness.effects:
			EffectResolver.resolve(effect, context)
		_log(LocalizedMessage.weakness_triggered(weakness))
	_apply_context(context)

func _apply_context(context: EffectContext) -> void:
	player_hp = context.player_hp
	player_block = context.player_block
	enemy_hp = context.enemy_hp
	doom = context.doom
	multiplier = context.multiplier

func _shuffle_with_run_rng(cards: Array[CardData]) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_index: int = RunState.roll_int(0, index)
		var card := cards[index]
		cards[index] = cards[swap_index]
		cards[swap_index] = card

func _check_finished() -> bool:
	if is_finished():
		return true
	if player_hp <= 0:
		state = State.DEFEAT
		victory = false
		RunState.player_hp = 0
		_log(LocalizedMessage.template(&"LOG_DEFEAT"))
		battle_finished.emit(false)
		return true
	if enemy_hp <= 0:
		state = State.VICTORY
		victory = true
		RunState.player_hp = player_hp
		_log(LocalizedMessage.template(&"LOG_VICTORY"))
		battle_finished.emit(true)
		return true
	return false

func _log(message: LocalizedMessage) -> void:
	log_added.emit(message)
