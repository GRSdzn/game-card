class_name EffectContext
extends RefCounted

## Mutable battle values passed through a card's ordered effect list.
## It keeps effect resolution typed and independent from BattleController's UI.
var player_hp: int
var player_block: int
var enemy_hp: int
var doom: int
var multiplier: int
var draw_requested: int = 0

func _init(
	initial_player_hp: int,
	initial_player_block: int,
	initial_enemy_hp: int,
	initial_doom: int,
	initial_multiplier: int
) -> void:
	player_hp = initial_player_hp
	player_block = initial_player_block
	enemy_hp = initial_enemy_hp
	doom = initial_doom
	multiplier = initial_multiplier
