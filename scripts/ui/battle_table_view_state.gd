class_name BattleTableViewState
extends RefCounted

var hand: Array[CardData] = []
var playable_cards: Array[bool] = []
var player_hp: int = 0
var max_player_hp: int = 1
var player_block: int = 0
var energy: int = 0
var max_energy: int = 1
var enemy_hp: int = 0
var doom: int = 0
var multiplier: int = 1
var weakness_names: String = ""
var draw_count: int = 0
var discard_count: int = 0
var played_cards: Array[CardData] = []
var last_combo: ComboResult = ComboResult.new()
var can_score: bool = false
var is_active: bool = false
