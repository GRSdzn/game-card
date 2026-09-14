extends Node

const BATTLE_TABLE_SCENE := preload("res://scenes/battle/battle_table.tscn")
const TEST_SETTINGS_PATH := "res://tests/.localization_test_settings.cfg"


func _ready() -> void:
	LocalizationManager.settings_path = TEST_SETTINGS_PATH
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))
	var success := await _run()
	LocalizationManager.set_locale("en", true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))
	LocalizationManager.settings_path = LocalizationManager.SETTINGS_PATH
	get_tree().quit(0 if success else 1)


func _run() -> bool:
	var loaded_locales := TranslationServer.get_loaded_locales()
	if not _expect("en" in loaded_locales and "ru" in loaded_locales, "English and Russian translation resources must load."):
		return false
	LocalizationManager.set_locale("en", false)
	if not _expect(LocalizationManager.translate(&"UI_SEAL_RITUAL") == "SEAL RITUAL", "English locale must resolve UI keys."):
		return false

	var table := BATTLE_TABLE_SCENE.instantiate() as BattleTable
	table.set_anchors_preset(Control.PRESET_TOP_LEFT)
	table.size = Vector2(1600, 900)
	add_child(table)
	await get_tree().process_frame
	var card := CardData.new()
	card.id = &"localized_fixture"
	card.title_key = &"CARD_HANGOVER_TITLE"
	card.description_key = &"CARD_HANGOVER_DESCRIPTION"
	card.cost = 0
	card.rank = 6
	card.suit = CardData.Suit.BLOOD
	var effect := EffectData.new()
	effect.type = EffectData.Type.GAIN_DOOM
	effect.amount = 4
	card.effects = [effect]
	table.render_battle([card], [true], 30, 30, 0, 3, 3, 24, 4, 1, "None", 5, 0, [], ComboResult.new(), false, true)
	table.append_log(LocalizedMessage.template(&"LOG_BATTLE_STARTED"))
	await get_tree().process_frame
	var english_inspector := table.enemy_label.text
	if not _expect(table.hand_view.card_views[0].title_label.text == "Hangover", "English card content must use its translation key."):
		return false

	LocalizationManager.set_locale("ru", true)
	await get_tree().process_frame
	if not _expect(LocalizationManager.translate(&"UI_SEAL_RITUAL") == "ЗАПЕЧАТАТЬ РИТУАЛ", "Russian locale must resolve UI keys."):
		return false
	if not _expect(table.enemy_label.text != english_inspector and "Целостность" in table.enemy_label.text and "Намерение" in table.enemy_label.text, "Runtime locale switching must refresh visible BattleTable labels."):
		return false
	if not _expect(table.hand_view.card_views[0].title_label.text == "Похмелье", "Russian card fixture must render Cyrillic content."):
		return false
	if not _expect(table.log_entries[0].resolve() == "Бой начался.", "Existing battle log messages must resolve in the active locale."):
		return false
	if not _expect(card.id == &"localized_fixture", "Card stable identity must be independent of language."):
		return false
	if not _expect(LocalizationManager._load_initial_locale() == "ru", "Selected language must persist for the next launch."):
		return false
	print("Localization tests passed.")
	return true


func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition
