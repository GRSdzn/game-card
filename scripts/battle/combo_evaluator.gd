class_name ComboEvaluator
extends RefCounted

## Evaluates exactly the cards committed to the current ritual.
## Rule priority is Procession, Black Mass, Triple, then Pair.
static func evaluate(cards: Array[CardData]) -> ComboResult:
	if cards.is_empty():
		return ComboResult.new()
	if _has_same_suit(cards, 5):
		return _result(&"procession", "Procession", &"COMBO_PROCESSION", 8, 2, cards)
	if _all_tagged(cards, &"curse"):
		return _result(&"black_mass", "Black Mass", &"COMBO_BLACK_MASS", 2, 2, cards)
	if _has_same_rank(cards, 3):
		return _result(&"triple", "Triple", &"COMBO_TRIPLE", 4, 1, cards)
	if _has_same_rank(cards, 2):
		return _result(&"pair", "Pair", &"COMBO_PAIR", 2, 1, cards)
	return ComboResult.new()

static func _has_same_rank(cards: Array[CardData], required_count: int) -> bool:
	if cards.size() != required_count:
		return false
	var rank := cards[0].rank
	for card in cards:
		if card.rank != rank:
			return false
	return true

static func _has_same_suit(cards: Array[CardData], required_count: int) -> bool:
	if cards.size() != required_count:
		return false
	var suit := cards[0].suit
	for card in cards:
		if card.suit != suit:
			return false
	return true

static func _all_tagged(cards: Array[CardData], tag: StringName) -> bool:
	for card in cards:
		if not (tag in card.tags):
			return false
	return true

static func _result(
	id: StringName,
	display_name: String,
	display_name_key: StringName,
	base_doom: int,
	multiplier: int,
	cards: Array[CardData]
) -> ComboResult:
	var result := ComboResult.new()
	result.id = id
	result.display_name = display_name
	result.display_name_key = display_name_key
	result.base_doom = base_doom
	result.multiplier = multiplier
	for card in cards:
		result.matched_card_ids.append(card.id)
	return result
