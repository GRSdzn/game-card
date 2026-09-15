class_name HandView
extends Control

signal play_requested(card_data: CardData)
signal inspect_requested(card_data: CardData)
signal preview_requested(card_data: CardData)

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")

var card_views: Array[CardView] = []

func _ready() -> void:
	resized.connect(_layout_cards)

func set_hand(cards: Array[CardData], playable_cards: Array[bool]) -> void:
	_clear_cards()
	for index in cards.size():
		var card_view := CARD_VIEW_SCENE.instantiate() as CardView
		add_child(card_view)
		card_view.display_card(cards[index], index < playable_cards.size() and playable_cards[index])
		card_view.play_requested.connect(_on_card_play_requested)
		card_view.inspect_requested.connect(_on_card_inspect_requested)
		card_view.preview_requested.connect(func(card: CardData) -> void: preview_requested.emit(card))
		card_views.append(card_view)
	call_deferred("_layout_cards")

func card_count() -> int:
	return card_views.size()

func _clear_cards() -> void:
	for card_view in card_views:
		card_view.queue_free()
	card_views.clear()

func _layout_cards() -> void:
	if card_views.is_empty():
		return
	var card_width: float = CardView.CARD_SIZE.x
	var card_height: float = CardView.CARD_SIZE.y
	var center_index := (card_views.size() - 1) * 0.5
	var available_width: float = maxf(0.0, size.x - card_width)
	# Five default cards fit across every supported battle surface. Keep faces
	# separate so title, art, and concise rule remain visible; hover still has a
	# small physical gap above its neighbours.
	var max_spacing := card_width + 6.0
	var spacing: float = minf(max_spacing, available_width / maxf(1.0, card_views.size() - 1.0))
	for index in card_views.size():
		var card_view := card_views[index]
		var distance_from_center: float = absf(index - center_index)
		var normalized_distance: float = distance_from_center / maxf(1.0, center_index)
		card_view.position = Vector2(
			(size.x - card_width) * 0.5 + (index - center_index) * spacing,
			size.y - card_height - 10.0 + normalized_distance * normalized_distance * 9.0
		)
		card_view.rotation = deg_to_rad((index - center_index) * 1.4)
		card_view.set_base_z_index(index)

func _on_card_play_requested(card_data: CardData) -> void:
	play_requested.emit(card_data)

func _on_card_inspect_requested(card_data: CardData) -> void:
	inspect_requested.emit(card_data)
