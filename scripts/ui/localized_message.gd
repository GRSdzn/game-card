class_name LocalizedMessage
extends RefCounted

enum Kind { TEMPLATE, CARD_PLAYED, COMBO_DAMAGE, WEAKNESS_TRIGGERED }

var kind: Kind = Kind.TEMPLATE
var key: StringName
var arguments: Dictionary = {}
var card: CardData
var combo: ComboResult
var weakness: WeaknessData

static func template(message_key: StringName, message_arguments: Dictionary = {}) -> LocalizedMessage:
	var message := LocalizedMessage.new()
	message.key = message_key
	message.arguments = message_arguments
	return message

static func card_played(played_card: CardData) -> LocalizedMessage:
	var message := LocalizedMessage.new()
	message.kind = Kind.CARD_PLAYED
	message.card = played_card
	return message

static func combo_damage(scored_combo: ComboResult, damage: int) -> LocalizedMessage:
	var message := LocalizedMessage.new()
	message.kind = Kind.COMBO_DAMAGE
	message.combo = scored_combo
	message.arguments = {"damage": damage}
	return message

static func weakness_triggered(triggered_weakness: WeaknessData) -> LocalizedMessage:
	var message := LocalizedMessage.new()
	message.kind = Kind.WEAKNESS_TRIGGERED
	message.weakness = triggered_weakness
	return message

func resolve() -> String:
	match kind:
		Kind.CARD_PLAYED:
			return LocalizationManager.translate(&"LOG_CARD_PLAYED", {
				"title": card.get_title(),
				"description": card.get_description(),
			})
		Kind.COMBO_DAMAGE:
			return LocalizationManager.translate(&"LOG_COMBO_DAMAGE", {
				"combo": combo.get_display_name(),
				"damage": arguments.get("damage", 0),
			})
		Kind.WEAKNESS_TRIGGERED:
			return LocalizationManager.translate(&"LOG_WEAKNESS_TRIGGERED", {"weakness": weakness.get_title()})
	return LocalizationManager.translate(key, arguments)
