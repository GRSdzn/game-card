class_name WeaknessRule
extends Resource

## Event predicates and repetition are data, independent from card or Vice IDs.
enum Condition { ALWAYS, SAME_SUIT, CHANGED_SUIT }
enum Repeat { ONCE, CARDS_IN_HAND }

@export var trigger: WeaknessData.Trigger = WeaknessData.Trigger.CARD_PLAYED
@export var condition: Condition = Condition.ALWAYS
@export var repeat: Repeat = Repeat.ONCE
@export var effects: Array[EffectData] = []

func matches(event: Dictionary) -> bool:
	var previous: int = event.get("previous_suit", -1)
	var current: int = event.get("suit", -1)
	match condition:
		Condition.SAME_SUIT: return previous >= 0 and current == previous
		Condition.CHANGED_SUIT: return previous >= 0 and current >= 0 and current != previous
	return true

func repetitions(event: Dictionary) -> int:
	return maxi(0, int(event.get("hand_count", 0))) if repeat == Repeat.CARDS_IN_HAND else 1
