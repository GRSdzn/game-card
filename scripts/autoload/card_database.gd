extends Node

var cards: Dictionary[StringName, CardData] = {}

func _ready() -> void:
	reload_cards()

func reload_cards() -> void:
	cards.clear()
	var file_names := ResourceLoader.list_directory("res://data/cards")
	if file_names.is_empty():
		push_error("CardDatabase: no card resources found in res://data/cards")
		return
	file_names.sort()
	for file_name in file_names:
		if not file_name.ends_with(".tres"):
			continue
		var resource := ResourceLoader.load("res://data/cards/%s" % file_name)
		if resource is CardData:
			if resource.id.is_empty():
				push_error("CardDatabase: card '%s' has an empty ID." % file_name)
			elif cards.has(resource.id):
				push_error("CardDatabase: duplicate card ID '%s'." % resource.id)
			else:
				cards[resource.id] = resource

func get_card(id: StringName) -> CardData:
	return cards.get(id) as CardData

func all_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	for card in cards.values():
		result.append(card)
	return result
