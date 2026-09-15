class_name EnemyIntentData
extends Resource

@export var id: StringName
@export var title_key: StringName
@export var damage: int = 5
@export var reduction_per_ritual: int = 0
@export var minimum_damage: int = 0

func damage_after(ritual_count: int) -> int:
	return maxi(minimum_damage, damage - ritual_count * reduction_per_ritual)
