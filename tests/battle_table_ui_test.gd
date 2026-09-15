extends Node

const BATTLE_TABLE_SCENE := preload("res://scenes/battle/battle_table.tscn")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const COMPOSITION_DEBUG_SCENE := preload("res://scenes/debug/battle_table_composition_debug.tscn")
const STYLE_KIT_REFERENCE_SCENE := preload("res://scenes/debug/style_kit_reference.tscn")
var play_intents: int = 0
var inspect_intents: int = 0

func _ready() -> void:
	var success := await _run()
	get_tree().quit(0 if success else 1)

func _run() -> bool:
	var table := BATTLE_TABLE_SCENE.instantiate() as BattleTable
	table.set_anchors_preset(Control.PRESET_TOP_LEFT)
	table.size = Vector2(1600, 900)
	add_child(table)
	await get_tree().process_frame
	if not _expect(
		table.player_label != null and table.enemy_label != null and table.ritual_label != null
			and table.deck_label != null and table.discard_label != null and table.hand_view != null
			and table.inspector_module != null and table.enemy_row != null and table.player_board_row != null,
		"BattleTable must create all table zones."
	):
		return false
	var surface_ratio: float = table.battle_surface.size.x / table.size.x
	if not _expect(surface_ratio >= 0.82 and surface_ratio <= 0.88, "Battle surface must occupy the broad physical table field at 1600px."):
		return false
	var test_card := CardData.new()
	test_card.id = &"ui_test_card"
	test_card.title = "Ledger Strike"
	test_card.description = "A deterministic presentation test."
	test_card.cost = 1
	test_card.rank = 4
	test_card.tags = [&"test"]
	var effect := EffectData.new()
	effect.type = EffectData.Type.DAMAGE
	effect.amount = 7
	test_card.effects = [effect]
	table.play_requested.connect(_on_play_requested)
	table.inspect_requested.connect(_on_inspect_requested)
	table.set_seed("TABLE-UI-001")
	table.render_battle(
		[test_card], [true], 30, 30, 0, 3, 3, 24, 0, 1, "None", 5, 0, [],
		ComboResult.new(), false, true
	)
	await get_tree().process_frame
	if not _expect(table.hand_view.card_count() == 1, "HandView must create one CardView per card."):
		return false
	var card_view := table.hand_view.card_views[0]
	if not _expect(card_view.card_data == test_card and card_view.is_playable, "CardView must render supplied CardData and playable state."):
		return false
	if not _expect(card_view.description_label.text != test_card.description, "Normal CardView must use concise effect text instead of full description."):
		return false
	card_view.play_requested.emit(test_card)
	if not _expect(play_intents == 1, "CardView play intent must flow through HandView and BattleTable."):
		return false
	if not _expect(card_view.position.x >= 0.0 and card_view.position.y >= 0.0, "HandView must place cards inside the table."):
		return false
	if not _expect(table.hand_view.size.y >= CardView.CARD_SIZE.y, "The table must reserve a full card-height hand zone."):
		return false
	card_view._on_mouse_entered()
	card_view._update_presentation(true)
	if not _expect(not table.hand_view.clip_contents and card_view.card_frame.position.y < 0.0 and card_view.z_index > 0, "Hovered cards must rise above the unclipped hand."):
		return false
	card_view.inspect_requested.emit(test_card)
	if not _expect(inspect_intents == 1, "CardView inspect intent must flow through HandView and BattleTable."):
		return false
	if not await _test_main_integration():
		return false
	if not await _test_composition_debug_scene():
		return false
	if not await _test_responsive_profiles():
		return false
	if not await _test_style_kit_reference():
		return false
	print("Battle table UI test passed.")
	return true

func _test_main_integration() -> bool:
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	var main_table := main.get("battle_table") as BattleTable
	var battle := main.get("battle") as BattleController
	var demo := main.get("demo") as DemoRunController
	if not _expect(demo.phase == DemoRunController.Phase.CHOOSING, "Main must offer a Vice before battle."):
		return false
	main.get("flow_view").choice_requested.emit(&"vice", &"greed")
	await get_tree().process_frame
	if not _expect(main_table.hand_view.card_count() == BattleController.HAND_SIZE, "Main scene must render the starter hand."):
		return false
	var first_card_view := main_table.hand_view.card_views[0]
	var hand_size_before := battle.hand.size()
	first_card_view.play_requested.emit(first_card_view.card_data)
	await get_tree().process_frame
	return _expect(
		battle.hand.size() == hand_size_before - 1 and main_table.hand_view.card_count() == battle.hand.size(),
		"A CardView intent must update BattleController and refresh the table."
	)

func _test_composition_debug_scene() -> bool:
	var debug_scene := COMPOSITION_DEBUG_SCENE.instantiate() as Control
	debug_scene.set_anchors_preset(Control.PRESET_TOP_LEFT)
	debug_scene.size = Vector2(1600, 900)
	add_child(debug_scene)
	await get_tree().process_frame
	var debug_table := debug_scene.get_child(0) as BattleTable
	if not _expect(debug_table.hand_view.card_count() == 5, "Composition debug scene must contain a known five-card hand."):
		return false
	for card_view in debug_table.hand_view.card_views:
		if not _expect(card_view.position.y + CardView.CARD_SIZE.y <= debug_table.hand_view.size.y + 1.0, "Every debug-hand card must remain fully visible."):
			return false
	debug_scene.size = Vector2(1920, 1080)
	await get_tree().process_frame
	var wide_ratio: float = debug_table.battle_surface.size.x / debug_table.size.x
	return _expect(wide_ratio >= 0.82 and wide_ratio <= 0.88, "Battle surface must remain a broad physical table at 1920×1080.")

func _test_responsive_profiles() -> bool:
	LocalizationManager.set_locale("ru", false)
	for viewport_size in [Vector2(1366, 768), Vector2(1600, 900), Vector2(1920, 1080)]:
		var responsive_table := BATTLE_TABLE_SCENE.instantiate() as BattleTable
		responsive_table.set_anchors_preset(Control.PRESET_TOP_LEFT)
		responsive_table.size = viewport_size
		add_child(responsive_table)
		await get_tree().process_frame
		var long_hand := _long_localized_hand()
		responsive_table.render_battle(
			long_hand, [true, true, true, true, false], 28, 30, 5, 2, 3, 24, 7, 2,
			"", 12, 8, long_hand, ComboResult.new(), true, true
		)
		responsive_table.append_log(LocalizedMessage.template(&"LOG_BATTLE_STARTED"))
		await get_tree().process_frame
		var surface_ratio: float = responsive_table.battle_surface.size.x / viewport_size.x
		if not _expect(surface_ratio >= 0.82 and surface_ratio <= 0.88, "Responsive table surface must retain gameplay priority."):
			return false
		if not _expect(responsive_table.enemy_label.size.x >= 250.0 and responsive_table.ritual_label.size.x >= 150.0, "Inspector and compact Ritual readouts must retain readable widths."):
			return false
		if not _expect(responsive_table.event_label.text.length() > 0 and responsive_table.event_label.size.x > 240.0, "Battle events must remain available to the archived log without dominating the table."):
			return false
		if not _expect(responsive_table.ritual_label.text.contains("+4") and not responsive_table.ritual_label.text.contains(" · "), "Ritual summary must use one title and a card count instead of an overflowing list."):
			return false
		for card_view in responsive_table.hand_view.card_views:
			if not _expect(card_view.title_label.size.x >= 90.0 and card_view.description_label.size.x >= 90.0, "Hand cards must reserve readable title and effect widths."):
				return false
			if not _expect(card_view.position.y + CardView.CARD_SIZE.y <= responsive_table.hand_view.size.y + 1.0, "Responsive hand cards must not clip vertically."):
				return false
		for index in responsive_table.hand_view.card_views.size() - 1:
			var left_card := responsive_table.hand_view.card_views[index]
			var right_card := responsive_table.hand_view.card_views[index + 1]
			if not _expect(right_card.position.x >= left_card.position.x + CardView.CARD_SIZE.x - 2.0, "Default five-card hand must not hide a neighbouring card face."):
				return false
		responsive_table.queue_free()
		await get_tree().process_frame
	LocalizationManager.set_locale("en", false)
	return true

func _long_localized_hand() -> Array[CardData]:
	var cards: Array[CardData] = []
	for index in 5:
		var card := CardData.new()
		card.id = StringName("responsive_fixture_%d" % index)
		card.title_key = &"CARD_HANGOVER_TITLE"
		card.description_key = &"CARD_HANGOVER_DESCRIPTION"
		card.cost = index % 3
		card.rank = index + 2
		card.suit = CardData.Suit.BLOOD
		var effect := EffectData.new()
		effect.type = EffectData.Type.GAIN_DOOM
		effect.amount = 4
		card.effects = [effect]
		cards.append(card)
	return cards

func _test_style_kit_reference() -> bool:
	for path in [
		"res://assets/ui/frame_utility.svg", "res://assets/ui/frame_mechanism.svg", "res://assets/ui/frame_unique.svg",
		"res://assets/ui/soot_overlay.svg", "res://assets/ui/scratches_overlay.svg", "res://assets/ui/vignette.svg",
		"res://assets/ui/gauge_face.svg",
	]:
		if not _expect(ResourceLoader.exists(path), "Style Kit v1 resources and Art Bible must exist."):
			return false
	if not _expect(FileAccess.file_exists("res://docs/ART_DIRECTION.md"), "Art Bible must exist."):
		return false
	var reference := STYLE_KIT_REFERENCE_SCENE.instantiate() as Control
	reference.set_anchors_preset(Control.PRESET_TOP_LEFT)
	reference.size = Vector2(1600, 900)
	add_child(reference)
	await get_tree().process_frame
	var reference_table := reference.get_child(0) as BattleTable
	if not _expect(reference_table != null and reference_table.hand_view.card_count() == 5, "Style Kit reference must contain a deterministic table and five-card hand."):
		return false
	if not _expect(reference_table.inspector_module != null and reference_table.ritual_centerpiece != null and reference_table.pressure_needle != null, "Style Kit reference must expose Inspector, Ritual, and pressure gauge."):
		return false
	reference.queue_free()
	return true

func _expect(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
	return condition

func _on_play_requested(_card: CardData) -> void:
	play_intents += 1

func _on_inspect_requested(_card: CardData) -> void:
	inspect_intents += 1
