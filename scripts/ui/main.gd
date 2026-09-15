extends Control

const BATTLE_TABLE_SCENE := preload("res://scenes/battle/battle_table.tscn")
var demo := DemoRunController.new()
var battle: BattleController = demo.battle
var battle_table: BattleTable
var flow_view: DemoFlowView

func _ready() -> void:
	battle_table = BATTLE_TABLE_SCENE.instantiate() as BattleTable
	add_child(battle_table)
	flow_view = DemoFlowView.new()
	flow_view.theme = battle_table.theme
	add_child(flow_view)
	battle.changed.connect(_refresh)
	battle.log_added.connect(battle_table.append_log)
	battle.enemy_attack_resolved.connect(battle_table.show_enemy_attack)
	battle.machine_resolved.connect(battle_table.show_machine_release)
	battle.machine_discharged.connect(battle_table.show_machine_discharge)
	demo.changed.connect(_refresh)
	battle_table.new_run_requested.connect(_new_run)
	battle_table.play_requested.connect(battle.play_card)
	battle_table.inspect_requested.connect(_inspect_card)
	battle_table.preview_requested.connect(_preview_card)
	battle_table.score_requested.connect(battle.score_played_set)
	battle_table.end_turn_requested.connect(battle.end_turn)
	battle_table.machine_mode_requested.connect(battle.choose_machine_mode)
	flow_view.choice_requested.connect(_choose)
	LocalizationManager.locale_changed.connect(func(_locale: String) -> void: _refresh())
	_new_run("DEAD-BEEF-001")

func _new_run(seed_text: String) -> void:
	battle_table.clear_log()
	demo.begin(seed_text)
	battle_table.set_seed(RunState.seed_text)

func _choose(kind: StringName, id: StringName) -> void:
	match kind:
		&"vice": demo.choose_vice(id)
		&"reward": demo.claim_reward(id)
		&"continue": demo.continue_shift()
		&"restart": _new_run(RunState.seed_text)

func _inspect_card(card: CardData) -> void:
	battle_table.append_log(LocalizedMessage.template(&"CARD_INSPECTION", {
		"title": card.get_title(), "description": card.get_description(),
	}))
	_preview_card(card)

func _refresh() -> void:
	if battle_table == null:
		return
	var active := demo.phase == DemoRunController.Phase.BATTLE and not battle.is_finished()
	var playable: Array[bool] = []
	for card in battle.hand:
		playable.append(active and battle.can_play(card))
	var displayed_hp := battle.player_hp if active or demo.phase == DemoRunController.Phase.DEFEAT else RunState.player_hp
	battle_table.render_battle(battle.hand, playable, displayed_hp, RunState.max_hp,
		battle.player_block, battle.energy, BattleController.MAX_ENERGY, battle.enemy_hp,
		battle.doom, battle.multiplier, battle.weakness_names(), battle.draw_pile.size(),
		battle.discard_pile.size(), battle.played_cards, battle.last_combo,
		active and battle.can_score_played_set(), active)
	var intent := battle.current_intent()
	if intent != null and not demo.selected_vice.is_empty():
		var title := _t(intent.title_key)
		var description := _t(&"INTENT_DETAIL", {"damage": battle.current_enemy_damage(), "block": battle.player_block})
		if intent.reduction_per_ritual > 0:
			description += "\n" + _t(&"INTENT_MITIGATION", {"amount": intent.reduction_per_ritual, "minimum": intent.minimum_damage})
		battle_table.render_demo_details(_t(&"INTENT_LINE", {"title": title, "damage": battle.current_enemy_damage()}),
			description, battle.enemy_max_hp, WeaknessDatabase.get_weakness(demo.selected_vice).get_description())
	_preview_card(null)
	_render_machine(active)
	if active:
		var current := battle.preview_ritual()
		var summary := _t(&"PREVIEW_COMBO", {"combo": current.combo.get_display_name(), "damage": current.ritual_damage}) if current.combo.is_match() else _t(&"COMBO_NONE")
		var turn := battle.preview_enemy_turn()
		battle_table.render_ritual_summary(summary, _t(&"END_TURN_FORECAST", turn))
	_render_flow()

func _render_machine(active: bool) -> void:
	var options: Array[Dictionary] = []
	if active:
		for mode in BattleController.MACHINE_MODES:
			var forecast := battle.preview_machine_mode(mode)
			var payload := _t(&"MACHINE_BOOST_COST", forecast) if not mode.ritual_effects.is_empty() else _t(&"MACHINE_VENT_GAIN", forecast)
			var title := _t(mode.title_key) + "\n" + payload
			if forecast["lethal"]:
				title = _t(mode.title_key) + "\n" + _t(&"MACHINE_LETHAL")
			var description := _t(&"MACHINE_PRESSURE_COST", forecast) + "\n" + payload
			if not mode.ritual_effects.is_empty():
				description += "\n" + _t(&"MACHINE_RISK_RULE")
			options.append({"id": mode.id, "title": title, "description": description, "lethal": forecast["lethal"]})
	var status := _t(&"MACHINE_READY") if battle.can_choose_machine_mode() else _t(&"MACHINE_LOCKED")
	if battle.machine_mode != null:
		status = _t(&"MACHINE_SPENT")
	if battle.machine_charge:
		status = _t(&"MACHINE_ARMED")
	battle_table.render_machine_options(options, status, active and battle.can_choose_machine_mode(), active and battle.machine_charge)

func _preview_card(card: CardData) -> void:
	if demo.phase != DemoRunController.Phase.BATTLE:
		return
	var preview := battle.preview_ritual(card)
	var lines: PackedStringArray = []
	lines.append(_t(&"PREVIEW_NOW") if card == null else card.get_title())
	if not preview.playable:
		lines.append(_t(&"PREVIEW_LOCKED"))
	else:
		if preview.lethal_self_damage:
			lines.append(_t(&"PREVIEW_LETHAL"))
		elif preview.card_ends_battle:
			lines.append(_t(&"PREVIEW_CARD_VICTORY"))
		elif preview.combo.is_match():
			lines.append(_t(&"PREVIEW_COMBO", {"combo": preview.combo.get_display_name(), "damage": preview.ritual_damage}))
		else:
			lines.append(_t(&"PREVIEW_BREAKS") if preview.breaks_combo else _t(&"PREVIEW_NO_COMBO"))
		lines.append(_t(&"PREVIEW_CHANGE", {"hp": "%+d" % preview.hp_delta, "block": "%+d" % preview.block_delta, "damage": preview.card_damage}))
		lines.append(_t(&"PREVIEW_AFTER", {"doom": preview.doom_after}))
		lines.append(_t(&"PREVIEW_ENEMY", {"damage": preview.enemy_damage_after}))
	battle_table.render_forecast("\n".join(lines))

func _render_flow() -> void:
	if demo.phase == DemoRunController.Phase.BATTLE:
		flow_view.dismiss()
		return
	var choices: Array[Dictionary] = []
	var outcome := DemoFlowView.Outcome.NONE
	var title: StringName
	var body: String
	match demo.phase:
		DemoRunController.Phase.CHOOSING:
			title = &"DEMO_CHOOSE_TITLE"
			body = _t(&"DEMO_CHOOSE_BODY")
			for id in DemoRunController.VICE_IDS:
				var vice := WeaknessDatabase.get_weakness(id)
				choices.append({"kind": &"vice", "id": id, "title": vice.get_title(), "description": vice.get_description()})
		DemoRunController.Phase.REWARD:
			outcome = DemoFlowView.Outcome.VICTORY
			title = &"DEMO_REWARD_TITLE"
			body = _t(&"DEMO_REWARD_BODY", {"hp": RunState.player_hp, "max": RunState.max_hp})
			for reward in DemoRunController.REWARDS:
				choices.append({"kind": &"reward", "id": reward.id, "title": _t(reward.title_key), "description": _t(reward.description_key)})
		DemoRunController.Phase.COMPLETE:
			outcome = DemoFlowView.Outcome.VICTORY
			title = &"DEMO_COMPLETE_TITLE"
			body = _t(&"DEMO_COMPLETE_BODY", {"hp": RunState.player_hp, "max": RunState.max_hp, "shift": RunState.floor_index})
			choices.append({"kind": &"continue", "id": &"", "title": _t(&"DEMO_CONTINUE")})
			choices.append({"kind": &"restart", "id": &"", "title": _t(&"DEMO_RESTART")})
		_:
			outcome = DemoFlowView.Outcome.DEFEAT
			title = &"DEMO_DEFEAT_TITLE"
			body = _t(&"DEMO_DEFEAT_BODY")
			choices.append({"kind": &"restart", "id": &"", "title": _t(&"DEMO_RESTART")})
	flow_view.present(_t(title), body, choices, title, outcome)

func _t(key: StringName, args: Dictionary = {}) -> String:
	return LocalizationManager.translate(key, args)
