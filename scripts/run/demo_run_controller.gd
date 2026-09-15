class_name DemoRunController
extends RefCounted

signal changed
enum Phase { CHOOSING, BATTLE, REWARD, COMPLETE, DEFEAT }
const ENCOUNTER := preload("res://data/enemies/demo_inspector.tres")
const REWARDS: Array[RewardData] = [preload("res://data/rewards/repair.tres"), preload("res://data/rewards/reinforce.tres")]
const VICE_IDS: Array[StringName] = [&"greed", &"obsession"]

var battle := BattleController.new()
var phase: Phase = Phase.CHOOSING
var selected_vice: StringName
var claimed_reward: StringName

func _init() -> void:
	battle.battle_finished.connect(_on_battle_finished)

func begin(seed_text: String) -> void:
	RunState.max_hp = 30
	RunState.start_new_run(seed_text)
	phase = Phase.CHOOSING
	selected_vice = &""
	claimed_reward = &""
	battle.state = BattleController.State.INACTIVE
	battle.machine_mode = null
	battle.machine_charge = false
	battle.hand.clear()
	battle.played_cards.clear()
	changed.emit()

func choose_vice(id: StringName) -> bool:
	if phase != Phase.CHOOSING or id not in VICE_IDS:
		return false
	selected_vice = id
	RunState.weakness_ids = [id]
	_start_battle()
	return true

func claim_reward(id: StringName) -> bool:
	if phase != Phase.REWARD:
		return false
	for reward in REWARDS:
		if reward.id != id:
			continue
		RunState.max_hp += reward.max_hp_gain
		RunState.player_hp = mini(RunState.max_hp, RunState.player_hp + reward.heal)
		RunState.floor_index += 1
		RunState.run_changed.emit()
		claimed_reward = id
		phase = Phase.COMPLETE
		changed.emit()
		return true
	return false

func continue_shift() -> bool:
	if phase != Phase.COMPLETE:
		return false
	_start_battle()
	return true

func _start_battle() -> void:
	phase = Phase.BATTLE
	claimed_reward = &""
	battle.start(RunState.starter_deck, ENCOUNTER)
	changed.emit()

func _on_battle_finished(victory: bool) -> void:
	phase = Phase.REWARD if victory else Phase.DEFEAT
	changed.emit()
