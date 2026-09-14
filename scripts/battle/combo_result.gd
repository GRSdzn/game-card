class_name ComboResult
extends RefCounted

var id: StringName = &"none"
var display_name: String = "No combination"
var display_name_key: StringName = &"COMBO_NONE"
var base_doom: int = 0
var multiplier: int = 1
var matched_card_ids: Array[StringName] = []

func is_match() -> bool:
	return id != &"none"

func get_display_name() -> String:
	return LocalizationManager.translate(display_name_key)
