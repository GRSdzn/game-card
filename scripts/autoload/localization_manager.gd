extends Node

signal locale_changed(locale: String)

const SETTINGS_PATH := "user://iron_covenant_settings.cfg"
const SETTINGS_SECTION := "localization"
const SETTINGS_KEY := "locale"
const FALLBACK_LOCALE := "en"
const SUPPORTED_LOCALES: PackedStringArray = ["en", "ru"]

var current_locale: String = FALLBACK_LOCALE
var settings_path: String = SETTINGS_PATH

func _ready() -> void:
	set_locale(_load_initial_locale(), false)

func set_locale(requested_locale: String, persist: bool = true) -> void:
	var normalized_locale := requested_locale.to_lower().strip_edges()
	if not (normalized_locale in SUPPORTED_LOCALES):
		normalized_locale = FALLBACK_LOCALE
	var changed := current_locale != normalized_locale
	current_locale = normalized_locale
	TranslationServer.set_locale(current_locale)
	if persist:
		_save_locale()
	if changed:
		locale_changed.emit(current_locale)

func translate(key: StringName, arguments: Dictionary = {}) -> String:
	var translated := TranslationServer.translate(key)
	if translated == String(key):
		translated = String(key)
	return translated.format(arguments)

func language_name(locale: String) -> String:
	return translate(&"LANGUAGE_ENGLISH") if locale == "en" else translate(&"LANGUAGE_RUSSIAN")

func _load_initial_locale() -> String:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var saved_locale := String(config.get_value(SETTINGS_SECTION, SETTINGS_KEY, ""))
		if saved_locale in SUPPORTED_LOCALES:
			return saved_locale
	var system_locale := OS.get_locale_language().to_lower()
	return system_locale if system_locale in SUPPORTED_LOCALES else FALLBACK_LOCALE

func _save_locale() -> void:
	var config := ConfigFile.new()
	config.set_value(SETTINGS_SECTION, SETTINGS_KEY, current_locale)
	var error := config.save(settings_path)
	if error != OK:
		push_error("LocalizationManager: failed to persist selected locale.")
