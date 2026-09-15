class_name WeaknessData
extends Resource

## Persistent run modifier. Its behavior is defined by a trigger and effects.
enum Trigger { BATTLE_STARTED, CARD_PLAYED, RITUAL_SCORED, ENEMY_TURN_STARTED }

@export var id: StringName
@export var title: String = "Weakness"
@export_multiline var description: String = ""
@export var title_key: StringName
@export var description_key: StringName
@export var trigger: Trigger = Trigger.BATTLE_STARTED
@export var effects: Array[EffectData] = []
@export var rules: Array[WeaknessRule] = []

func trigger_name() -> String:
	return Trigger.keys()[trigger].capitalize().replace("_", " ")

func get_title() -> String:
	return LocalizationManager.translate(title_key) if not title_key.is_empty() else title

func get_description() -> String:
	return LocalizationManager.translate(description_key) if not description_key.is_empty() else description
