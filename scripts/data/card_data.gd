class_name CardData
extends Resource

## Pure card data. No battle logic should live in this resource.
enum Suit { BONE, BLOOD, FLESH, SPIRIT, GOLD }
enum Rarity { COMMON, UNCOMMON, RARE, CURSED }

@export var id: StringName
@export var title: String = "Карта"
@export_multiline var description: String = ""
@export var title_key: StringName
@export var description_key: StringName
## Presentation-only asset reference. Gameplay identity remains the stable card ID.
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var art_path: String = ""
@export_range(0, 9, 1) var cost: int = 1
@export_range(0, 13, 1) var rank: int = 1
@export var suit: Suit = Suit.BONE
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []
@export var effects: Array[EffectData] = []

func suit_name() -> String:
	var suit_keys: Array[StringName] = [&"SUIT_BONE", &"SUIT_BLOOD", &"SUIT_FLESH", &"SUIT_SPIRIT", &"SUIT_GOLD"]
	return LocalizationManager.translate(suit_keys[suit])

func get_title() -> String:
	return LocalizationManager.translate(title_key) if not title_key.is_empty() else title

func get_description() -> String:
	return LocalizationManager.translate(description_key) if not description_key.is_empty() else description
