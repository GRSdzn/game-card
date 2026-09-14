extends Control

const BATTLE_TABLE_SCENE := preload("res://scenes/battle/battle_table.tscn")

var battle := BattleController.new()
var battle_table: BattleTable

func _ready() -> void:
	battle_table = BATTLE_TABLE_SCENE.instantiate() as BattleTable
	add_child(battle_table)
	battle.changed.connect(_refresh)
	battle.log_added.connect(battle_table.append_log)
	battle.battle_finished.connect(_on_battle_finished)
	battle_table.new_run_requested.connect(_new_run)
	battle_table.play_requested.connect(battle.play_card)
	battle_table.inspect_requested.connect(_inspect_card)
	battle_table.score_requested.connect(battle.score_played_set)
	battle_table.end_turn_requested.connect(battle.end_turn)
	RunState.start_new_run("DEAD-BEEF-001")
	battle_table.set_seed(RunState.seed_text)
	battle.start(RunState.starter_deck)
	_refresh()

func _new_run(seed_text: String) -> void:
	battle_table.clear_log()
	RunState.start_new_run(seed_text)
	battle_table.set_seed(RunState.seed_text)
	battle.start(RunState.starter_deck)

func _inspect_card(card_data: CardData) -> void:
	battle_table.append_log(LocalizedMessage.template(&"CARD_INSPECTION", {
		"title": card_data.get_title(),
		"description": card_data.get_description(),
	}))

func _refresh() -> void:
	var playable_cards: Array[bool] = []
	for card in battle.hand:
		playable_cards.append(battle.can_play(card))
	battle_table.render_battle(
		battle.hand,
		playable_cards,
		battle.player_hp,
		RunState.max_hp,
		battle.player_block,
		battle.energy,
		BattleController.MAX_ENERGY,
		battle.enemy_hp,
		battle.doom,
		battle.multiplier,
		battle.weakness_names(),
		battle.draw_pile.size(),
		battle.discard_pile.size(),
		battle.played_cards,
		battle.last_combo,
		battle.can_score_played_set(),
		not battle.is_finished()
	)

func _on_battle_finished(_victory: bool) -> void:
	_refresh()
