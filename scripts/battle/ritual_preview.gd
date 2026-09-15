class_name RitualPreview
extends RefCounted

## A pure forecast of playing one card (optional), then sealing immediately.
var playable: bool = true
var combo: ComboResult = ComboResult.new()
var ritual_damage: int = 0
var machine_bonus: int = 0
var card_damage: int = 0
var hp_delta: int = 0
var block_delta: int = 0
var doom_after: int = 0
var multiplier_after: int = 1
var breaks_combo: bool = false
var lethal_self_damage: bool = false
var card_ends_battle: bool = false
var draw_requested: int = 0
var enemy_damage_after: int = 0
