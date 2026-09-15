class_name BattleController
extends RefCounted

signal changed
signal battle_finished(victory: bool)
signal log_added(message: LocalizedMessage)
signal enemy_attack_resolved(damage: int, blocked: int)
signal machine_resolved(charged: bool)
signal machine_discharged

const HAND_SIZE := 5
const MAX_ENERGY := 3
const MACHINE_MODES: Array[MachineModeData] = [preload("res://data/machine/vent.tres"), preload("res://data/machine/overload.tres")]

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
var encounter: EncounterData
var enemy_max_hp: int = 24
var turn_index: int = 0
var rituals_this_turn: int = 0
var previous_suit: int = -1
var machine_mode: MachineModeData
var machine_charge: bool = false

func start(deck_ids: Array[StringName], encounter_data: EncounterData = null) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	played_cards.clear()
	weaknesses.clear()
	energy = MAX_ENERGY
	player_hp = RunState.player_hp
	player_block = 0
	encounter = encounter_data
	enemy_max_hp = encounter.max_hp if encounter != null else 24
	enemy_hp = enemy_max_hp
	enemy_damage = 6
	turn_index = 0
	rituals_this_turn = 0
	previous_suit = -1
	machine_mode = null
	machine_charge = false
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

func can_choose_machine_mode() -> bool:
	return state == State.ACTIVE and energy == MAX_ENERGY and machine_mode == null

func choose_machine_mode(id: StringName) -> bool:
	if not can_choose_machine_mode():
		return false
	for mode in MACHINE_MODES:
		if mode.id != id or mode.pressure_cost > energy:
			continue
		machine_mode = mode
		energy -= mode.pressure_cost
		var context := _context()
		for effect in mode.activation_effects:
			EffectResolver.resolve(effect, context)
		_apply_context(context)
		machine_charge = not mode.ritual_effects.is_empty()
		_log(LocalizedMessage.template(mode.status_key))
		if not _check_finished() and context.draw_requested > 0:
			draw(context.draw_requested)
		changed.emit()
		if state == State.ACTIVE:
			machine_resolved.emit(machine_charge)
		return true
	return false

func preview_machine_mode(mode: MachineModeData) -> Dictionary:
	var context := _context()
	for effect in mode.activation_effects:
		EffectResolver.resolve(effect, context)
	return {"pressure": mode.pressure_cost, "hp_loss": player_hp - context.player_hp,
		"block": context.player_block - player_block, "bonus": _machine_damage(mode),
		"lethal": context.player_hp <= 0}

func _machine_damage(mode: MachineModeData) -> int:
	var damage := 0
	if mode != null:
		for effect in mode.ritual_effects:
			if effect.type == EffectData.Type.DAMAGE:
				damage += effect.amount
	return damage

func _resolve_machine_ritual(context: EffectContext) -> void:
	if machine_charge and machine_mode != null:
		for effect in machine_mode.ritual_effects:
			EffectResolver.resolve(effect, context)

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
	_trigger_weaknesses(WeaknessData.Trigger.CARD_PLAYED, {"previous_suit": previous_suit, "suit": card.suit})
	previous_suit = card.suit
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
	var discharged := machine_charge
	var context := _context()
	var strike := EffectData.new()
	strike.type = EffectData.Type.DAMAGE
	strike.amount = damage
	EffectResolver.resolve(strike, context)
	_resolve_machine_ritual(context)
	if machine_charge:
		damage += _machine_damage(machine_mode)
	_apply_context(context)
	machine_charge = false
	_log(LocalizedMessage.combo_damage(combo, damage))
	doom = 0
	played_cards.clear()
	rituals_this_turn += 1
	_trigger_weaknesses(WeaknessData.Trigger.RITUAL_SCORED)
	_check_finished()
	changed.emit()
	if discharged:
		machine_discharged.emit()

func end_turn() -> void:
	if state != State.ACTIVE:
		return
	if machine_charge:
		_log(LocalizedMessage.template(&"MACHINE_EXPIRED"))
	machine_charge = false
	if not played_cards.is_empty():
		_log(LocalizedMessage.template(&"LOG_UNSCORED_CARDS"))
		played_cards.clear()
	_trigger_weaknesses(WeaknessData.Trigger.ENEMY_TURN_STARTED)
	if _check_finished():
		changed.emit()
		return
	var damage: int = maxi(0, current_enemy_damage() - player_block)
	var attack := EffectData.new()
	attack.type = EffectData.Type.ATTACK_PLAYER
	attack.amount = current_enemy_damage()
	var blocked := mini(player_block, attack.amount)
	var attack_context := _context()
	EffectResolver.resolve(attack, attack_context)
	_apply_context(attack_context)
	player_block = 0
	_log(LocalizedMessage.template(&"LOG_ENEMY_DAMAGE", {"damage": damage}))
	if _check_finished():
		changed.emit()
		enemy_attack_resolved.emit(damage, blocked)
		return
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	energy = MAX_ENERGY
	turn_index += 1
	rituals_this_turn = 0
	previous_suit = -1
	machine_mode = null
	draw(HAND_SIZE)
	changed.emit()
	enemy_attack_resolved.emit(damage, blocked)

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

func _trigger_weaknesses(trigger: WeaknessData.Trigger, event: Dictionary = {}) -> void:
	var context := _context()
	event["hand_count"] = hand.size()
	var triggered := _resolve_weaknesses(trigger, context, event)
	_apply_context(context)
	for weakness in triggered:
		_log(LocalizedMessage.weakness_triggered(weakness))
	if context.draw_requested > 0 and player_hp > 0 and enemy_hp > 0:
		draw(context.draw_requested)

func _resolve_weaknesses(trigger: WeaknessData.Trigger, context: EffectContext, event: Dictionary) -> Array[WeaknessData]:
	var triggered: Array[WeaknessData] = []
	for weakness in weaknesses:
		var applied := false
		if weakness.trigger == trigger:
			for effect in weakness.effects:
				EffectResolver.resolve(effect, context)
				applied = true
		for rule in weakness.rules:
			if rule.trigger != trigger or not rule.matches(event):
				continue
			for _repeat in rule.repetitions(event):
				for effect in rule.effects:
					EffectResolver.resolve(effect, context)
					applied = true
		if applied:
			triggered.append(weakness)
	return triggered

func _context() -> EffectContext:
	return EffectContext.new(player_hp, player_block, enemy_hp, doom, multiplier)

func current_intent() -> EnemyIntentData:
	if encounter == null or encounter.intents.is_empty():
		return null
	return encounter.intents[turn_index % encounter.intents.size()]

func current_enemy_damage(extra_rituals: int = 0) -> int:
	var intent := current_intent()
	return intent.damage_after(rituals_this_turn + extra_rituals) if intent != null else enemy_damage

func preview_ritual(card: CardData = null) -> RitualPreview:
	var result := RitualPreview.new()
	result.playable = state == State.ACTIVE and (card == null or can_play(card))
	result.doom_after = doom
	result.multiplier_after = multiplier
	result.enemy_damage_after = current_enemy_damage()
	if not result.playable:
		return result
	var context := _context()
	var committed: Array[CardData] = played_cards.duplicate()
	var remaining_hand := hand.size()
	if card != null:
		for effect in card.effects:
			EffectResolver.resolve(effect, context)
		remaining_hand -= 1
		_resolve_weaknesses(WeaknessData.Trigger.CARD_PLAYED, context, {
			"previous_suit": previous_suit, "suit": card.suit, "hand_count": remaining_hand,
		})
		committed.append(card)
		result.card_damage = enemy_hp - context.enemy_hp
		# Drawing changes the number of cards seen by ritual-triggered rules,
		# but not the committed combination. Predict the count without shuffling
		# or revealing future identities. The just-played card is in discard.
		remaining_hand += mini(context.draw_requested, draw_pile.size() + discard_pile.size() + 1)
	result.card_ends_battle = context.enemy_hp <= 0 or context.player_hp <= 0
	result.combo = ComboEvaluator.evaluate(committed)
	result.breaks_combo = can_score_played_set() and not result.combo.is_match()
	if result.combo.is_match() and not result.card_ends_battle:
		result.ritual_damage = (context.doom + result.combo.base_doom) * context.multiplier * result.combo.multiplier
		context.enemy_hp = maxi(0, context.enemy_hp - result.ritual_damage)
		_resolve_machine_ritual(context)
		if machine_charge:
			result.machine_bonus = _machine_damage(machine_mode)
			result.ritual_damage += result.machine_bonus
		context.doom = 0
		_resolve_weaknesses(WeaknessData.Trigger.RITUAL_SCORED, context, {"hand_count": remaining_hand})
		result.enemy_damage_after = current_enemy_damage(1)
	result.hp_delta = context.player_hp - player_hp
	result.block_delta = context.player_block - player_block
	result.doom_after = context.doom
	result.multiplier_after = context.multiplier
	result.lethal_self_damage = context.player_hp <= 0
	result.draw_requested = context.draw_requested
	return result

func preview_enemy_turn() -> Dictionary:
	var context := _context()
	if state == State.ACTIVE:
		_resolve_weaknesses(WeaknessData.Trigger.ENEMY_TURN_STARTED, context, {"hand_count": hand.size()})
		if context.player_hp > 0 and context.enemy_hp > 0:
			var attack := EffectData.new()
			attack.type = EffectData.Type.ATTACK_PLAYER
			attack.amount = current_enemy_damage()
			EffectResolver.resolve(attack, context)
	return {"hp_loss": player_hp - context.player_hp, "doom_gain": context.doom - doom}

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
		machine_charge = false
		state = State.DEFEAT
		victory = false
		RunState.player_hp = 0
		_log(LocalizedMessage.template(&"LOG_DEFEAT"))
		battle_finished.emit(false)
		return true
	if enemy_hp <= 0:
		machine_charge = false
		state = State.VICTORY
		victory = true
		RunState.player_hp = player_hp
		_log(LocalizedMessage.template(&"LOG_VICTORY"))
		battle_finished.emit(true)
		return true
	return false

func _log(message: LocalizedMessage) -> void:
	log_added.emit(message)
