class_name MachineModeData
extends Resource

## One full-pressure action. All gameplay payloads use the central effect system.
@export var id: StringName
@export var title_key: StringName
@export var status_key: StringName
@export var pressure_cost: int = 1
@export var activation_effects: Array[EffectData] = []
@export var ritual_effects: Array[EffectData] = []
