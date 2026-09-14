extends Control

const BATTLE_TABLE_SCENE := preload("res://scenes/battle/battle_table.tscn")
const GRAVE_KICK := preload("res://data/cards/grave_kick.tres")
const BONE_GUARD := preload("res://data/cards/bone_guard.tres")
const HANGOVER := preload("res://data/cards/hangover.tres")

func _ready() -> void:
	# Debug-only visual validation. It changes locale presentation for this process
	# without persisting settings or touching the battle model.
	if "--art-locale=en" in OS.get_cmdline_user_args():
		LocalizationManager.set_locale("en", false)
	elif "--art-locale=ru" in OS.get_cmdline_user_args():
		LocalizationManager.set_locale("ru", false)
	var table := BATTLE_TABLE_SCENE.instantiate() as BattleTable
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(table)
	await get_tree().process_frame
	var hand := _known_hand()
	var show_empty_table := "--art-empty-hand" in OS.get_cmdline_user_args()
	var displayed_hand: Array[CardData] = []
	var committed: Array[CardData] = []
	if not show_empty_table:
		displayed_hand = hand
		committed.append(hand[0])
		committed.append(hand[1])
	table.set_seed("COMPOSITION-1920-900")
	table.render_battle(
		displayed_hand, [true, true, false, true, true], 23, 30, 4, 2, 3, 31, 6, 2,
		"%s · %s" % [
			LocalizationManager.translate(&"WEAKNESS_LATE_FEE"),
			LocalizationManager.translate(&"WEAKNESS_DELIRIUM"),
		], 12, 8, committed, ComboResult.new(), true, true
	)
	table.append_log(LocalizedMessage.template(&"DEBUG_LOG_KNOWN_HAND"))
	# Standalone window stretching can complete after the first debug render.
	# Reapply the existing UI snapshot once; no model, RNG, or effects are touched.
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(table):
		table.call_deferred("_apply_view_state")
	if "--art-probe" in OS.get_cmdline_user_args():
		await get_tree().process_frame
		print("ART_PROBE table=", table.size, " surface=", table.battle_surface.position, "/", table.battle_surface.size)
		print("ART_PROBE inspector=", table.inspector_module.position, "/", table.inspector_module.size)
		print("ART_PROBE ritual=", table.ritual_centerpiece.position, "/", table.ritual_centerpiece.size)
		get_tree().quit()

func _known_hand() -> Array[CardData]:
	var hand: Array[CardData] = []
	hand.append(GRAVE_KICK)
	hand.append(BONE_GUARD)
	hand.append(HANGOVER)
	for index in 2:
		var card := CardData.new()
		card.id = StringName("debug_card_%d" % (index + 3))
		card.title_key = [
			&"DEBUG_CARD_TITLE_4", &"DEBUG_CARD_TITLE_5",
		][index]
		card.description_key = &"DEBUG_CARD_DESCRIPTION"
		card.cost = index % 3
		card.rank = index + 2
		card.suit = index % CardData.Suit.size()
		card.tags = [&"debug", &"apparatus"]
		var effect := EffectData.new()
		effect.type = EffectData.Type.DAMAGE if index % 2 == 0 else EffectData.Type.BLOCK
		effect.amount = index + 2
		card.effects = [effect]
		hand.append(card)
	return hand
