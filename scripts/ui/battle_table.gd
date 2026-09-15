class_name BattleTable
extends Control

## This scene is a presentation shell. It only mirrors BattleController state and
## forwards user intent; no battle state, effects, or gameplay RNG live here.

signal new_run_requested(seed_text: String)
signal play_requested(card_data: CardData)
signal inspect_requested(card_data: CardData)
signal preview_requested(card_data: CardData)
signal score_requested
signal end_turn_requested
signal machine_mode_requested(id: StringName)

const HAND_VIEW_SCENE := preload("res://scenes/cards/hand_view.tscn")
const CINEMATIC_IRON_TEXTURE := preload("res://assets/textures/materials/mat_black_iron_cinematic_01.png")
const TABLE_APPARATUS_TEXTURE := preload("res://assets/textures/ui/battle_table_apparatus_01.png")
const TABLE_WOOD_TEXTURE := preload("res://assets/ui/dark_wood_01.svg")
const BRASS_TEXTURE := preload("res://assets/ui/oxidized_brass_01.svg")
const PARCHMENT_TEXTURE := preload("res://assets/ui/dirty_parchment_01.svg")
const INSPECTOR_PORTRAIT_TEXTURE := preload("res://assets/textures/inspector/inspector_portrait_01.png")
const INSPECTOR_MASK_TEXTURE := preload("res://assets/ui/inspector_mask.svg")
const RITUAL_EMBLEM_TEXTURE := preload("res://assets/ui/ritual_emblem.svg")
const RITUAL_MACHINE_TEXTURE := preload("res://assets/ui/ritual_machine_ring.svg")
const GAUGE_FACE_TEXTURE := preload("res://assets/ui/gauge_face.svg")
const CARD_BACK_TEXTURE := preload("res://assets/ui/card_back_iron_covenant.svg")
const FACTORY_BACKGROUND_TEXTURE := preload("res://assets/textures/environment/factory_ministry_01.png")

const COAL := Color("0d0e0d")
const IRON := Color("171817")
const DARK_IRON := Color("23221f")
const BRASS := Color("8b612c")
const BRASS_LIGHT := Color("b9823e")
const PARCHMENT := Color("d0b784")
const AMBER := Color("e0a04a")
const TEAL := Color("79c4c6")
const DANGER := Color("d15a4d")

enum LayoutProfile { WIDE, STANDARD, COMPACT }

var seed_edit: LineEdit
var player_label: Label
var pressure_label: Label
var doom_label: Label
var weaknesses_label: Label
var enemy_label: Label
var ritual_label: Label
var deck_label: Label
var discard_label: Label
var log_label: RichTextLabel
var event_label: Label
var score_button: Button
var end_turn_button: Button
var hand_view: HandView
var hp_vessel: ProgressBar
var pressure_needle: Control
var archive_controls: VBoxContainer
var battle_surface: Panel
var inspector_module: Panel
var enemy_row: HBoxContainer
var ritual_centerpiece: Panel
var player_board_row: HBoxContainer
var pressure_lamps: Array[Panel] = []
var log_entries: Array[LocalizedMessage] = []
var current_state: BattleTableViewState
var displayed_seed := ""
var language_option: OptionButton
var layout_profile: LayoutProfile = LayoutProfile.COMPACT
var ritual_emblem_art: TextureRect
var ritual_counter_label: Label
var ritual_status_light: Panel
var inspector_integrity: ProgressBar
var combo_dial_label: Label
var forecast_label: Label
var forecast_panel: Panel
var demo_intent: String = ""
var demo_intent_tooltip: String = ""
var demo_enemy_max_hp: int = 24
var demo_vice_tooltip: String = ""
var forecast_text: String = ""
var demo_ritual_text: String = ""
var demo_end_turn_tooltip: String = ""
var pressure_feedback: InstrumentFeedback
var protection_feedback: InstrumentFeedback
var enemy_turn_feedback: EnemyTurnFeedback
var machine_feedback: MachineFeedback
var machine_plate: Panel
var machine_status: Label
var machine_buttons: Array[Button] = []
var machine_options: Array[Dictionary] = []
var machine_status_text: String = ""
var machine_available: bool = false
var machine_charged: bool = false


func _ready() -> void:
	theme = _make_presentation_theme()
	layout_profile = _layout_profile_for_width(size.x)
	_build_table()
	resized.connect(_on_resized)
	LocalizationManager.locale_changed.connect(_on_locale_changed)


func set_seed(seed_text: String) -> void:
	displayed_seed = seed_text
	if seed_edit != null:
		seed_edit.text = seed_text


func render_battle(
	hand: Array[CardData], playable_cards: Array[bool], player_hp: int, max_player_hp: int,
	player_block: int, energy: int, max_energy: int, enemy_hp: int, doom: int, multiplier: int,
	weakness_names: String, draw_count: int, discard_count: int, played_cards: Array[CardData],
	last_combo: ComboResult, can_score: bool, is_active: bool
) -> void:
	var previous_state := current_state
	current_state = BattleTableViewState.new()
	current_state.hand = hand
	current_state.playable_cards = playable_cards
	current_state.player_hp = player_hp
	current_state.max_player_hp = max_player_hp
	current_state.player_block = player_block
	current_state.energy = energy
	current_state.max_energy = max_energy
	current_state.enemy_hp = enemy_hp
	current_state.doom = doom
	current_state.multiplier = multiplier
	current_state.weakness_names = weakness_names
	current_state.draw_count = draw_count
	current_state.discard_count = discard_count
	current_state.played_cards = played_cards
	current_state.last_combo = last_combo
	current_state.can_score = can_score
	current_state.is_active = is_active
	_apply_view_state()
	_animate_presentation_delta(previous_state)


func clear_log() -> void:
	if is_instance_valid(enemy_turn_feedback):
		enemy_turn_feedback.cancel()
	if is_instance_valid(machine_feedback):
		machine_feedback.cancel()
	log_entries.clear()
	_render_log()


func append_log(message: LocalizedMessage) -> void:
	log_entries.append(message)
	_render_log()


func _build_table() -> void:
	var stage := Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	_add_environment(stage)
	_add_outer_chassis(stage)
	_add_battle_surface(stage)
	_add_edge_instruments(stage)
	_add_field_apparatus(stage)
	IronStyleKit.add_vignette(stage)
	enemy_turn_feedback = EnemyTurnFeedback.new()
	enemy_turn_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(enemy_turn_feedback)

func show_enemy_attack(damage: int, blocked: int) -> void:
	var origin := inspector_module.global_position + Vector2(_portrait_size() * 0.6, _inspector_dimensions().y * 0.4)
	var destination := hp_vessel.get_global_rect().get_center()
	if damage == 0:
		destination.x += 48.0
	enemy_turn_feedback.play_attack(origin - global_position, destination - global_position,
		Rect2(battle_surface.global_position - global_position, battle_surface.size), end_turn_button, damage, blocked)


func _add_environment(stage: Control) -> void:
	var world := TextureRect.new()
	world.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	world.texture = FACTORY_BACKGROUND_TEXTURE
	world.modulate = Color(0.88, 0.76, 0.58, 0.88)
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(world)
	var occlusion := ColorRect.new()
	occlusion.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	occlusion.color = Color(0.02, 0.025, 0.025, 0.24)
	occlusion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(occlusion)


func _add_outer_chassis(stage: Control) -> void:
	var chassis := Panel.new()
	chassis.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chassis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chassis.add_theme_stylebox_override("panel", _frame_style(Color(0.03, 0.035, 0.033, 0.28), Color("080908"), 22, 0, 18))
	stage.add_child(chassis)
	_add_texture(chassis, CINEMATIC_IRON_TEXTURE, 0.20, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_add_pipework(chassis)
	# Heavy upper and lower rails interrupt the screen silhouette without becoming
	# dashboard columns.
	for rail_y in [12.0, maxf(20.0, size.y - 44.0)]:
		var rail := Panel.new()
		rail.position = Vector2(28.0, rail_y)
		rail.size = Vector2(maxf(80.0, size.x - 56.0), 26.0)
		rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rail.add_theme_stylebox_override("panel", _frame_style(IRON, Color("4b351e"), 5, 2, 6))
		chassis.add_child(rail)
		_add_texture(rail, CINEMATIC_IRON_TEXTURE, 0.32, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		_add_rivets(rail, 5)
	var title := _label(_t(&"UI_TITLE"), 15, PARCHMENT)
	title.position = Vector2(52.0, 15.0)
	title.size = Vector2(280.0, 22.0)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chassis.add_child(title)


func _add_pipework(chassis: Control) -> void:
	# The side members are structural silhouettes, not HUD columns. They break the
	# rectangle and make the table read as an installed factory machine.
	for x_anchor in [0.055, 0.945]:
		var pipe := Panel.new()
		pipe.anchor_left = x_anchor
		pipe.anchor_right = x_anchor
		pipe.anchor_top = 0.145
		pipe.anchor_bottom = 0.865
		pipe.offset_left = -13.0
		pipe.offset_right = 13.0
		pipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pipe.add_theme_stylebox_override("panel", _frame_style(Color("141412"), Color("6a4723"), 5, 10, 8))
		chassis.add_child(pipe)
		for y_anchor in [0.20, 0.52, 0.82]:
			var valve := Panel.new()
			valve.anchor_left = 0.5
			valve.anchor_right = 0.5
			valve.anchor_top = y_anchor
			valve.anchor_bottom = y_anchor
			valve.offset_left = -14.0
			valve.offset_right = 14.0
			valve.offset_top = -14.0
			valve.offset_bottom = 14.0
			valve.mouse_filter = Control.MOUSE_FILTER_IGNORE
			valve.add_theme_stylebox_override("panel", _lamp_style(false, BRASS_LIGHT))
			pipe.add_child(valve)
		var elbow := Panel.new()
		elbow.anchor_left = 0.0 if x_anchor < 0.5 else 1.0
		elbow.anchor_right = elbow.anchor_left
		elbow.anchor_top = 0.55
		elbow.anchor_bottom = 0.55
		elbow.offset_left = 0.0 if x_anchor < 0.5 else -76.0
		elbow.offset_right = 76.0 if x_anchor < 0.5 else 0.0
		elbow.offset_top = -7.0
		elbow.offset_bottom = 7.0
		elbow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elbow.add_theme_stylebox_override("panel", _frame_style(Color("171513"), Color("6a4723"), 3, 4, 4))
		pipe.add_child(elbow)


func _add_battle_surface(stage: Control) -> void:
	battle_surface = Panel.new()
	battle_surface.anchor_left = 0.075
	battle_surface.anchor_right = 0.925
	battle_surface.anchor_top = 0.065
	battle_surface.anchor_bottom = 0.955
	battle_surface.offset_left = 0.0
	battle_surface.offset_right = 0.0
	battle_surface.offset_top = 0.0
	battle_surface.offset_bottom = 0.0
	battle_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_surface.add_theme_stylebox_override("panel", _frame_style(Color("101211"), Color("725027"), 14, 5, 16))
	stage.add_child(battle_surface)
	_add_texture(battle_surface, CINEMATIC_IRON_TEXTURE, 0.18, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_add_texture(battle_surface, TABLE_APPARATUS_TEXTURE, 0.92, TextureRect.STRETCH_SCALE)
	_add_texture(battle_surface, TABLE_WOOD_TEXTURE, 0.03, TextureRect.STRETCH_TILE)
	_add_table_structure()
	_add_inspector()
	_add_enemy_row()
	_add_ritual_machine()
	_add_player_board()
	_add_event_strip()
	_add_hand()
	_add_forecast_plate()


func _add_table_structure() -> void:
	# Recessed brass rails keep an empty board readable as a physical apparatus.
	for y_ratio in [0.30, 0.70]:
		var rail := Panel.new()
		rail.anchor_left = 0.075
		rail.anchor_right = 0.925
		rail.anchor_top = y_ratio
		rail.anchor_bottom = y_ratio
		rail.offset_top = -4.0
		rail.offset_bottom = 4.0
		rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rail.add_theme_stylebox_override("panel", _frame_style(Color("0e0f0e"), Color("66471f"), 2, 3, 3))
		battle_surface.add_child(rail)


func _add_inspector() -> void:
	var dimensions := _inspector_dimensions()
	inspector_module = Panel.new()
	_place_centered(inspector_module, 14.0, dimensions.x, dimensions.y)
	inspector_module.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspector_module.add_theme_stylebox_override("panel", _frame_style(Color("131312"), Color("8d612d"), 12, 4, 16))
	battle_surface.add_child(inspector_module)
	_add_texture(inspector_module, CINEMATIC_IRON_TEXTURE, 0.34, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_add_rivets(inspector_module, 4)
	var portrait_size := _portrait_size()
	var socket := Panel.new()
	socket.position = Vector2(14.0, 12.0)
	socket.size = Vector2(portrait_size, dimensions.y - 24.0)
	socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socket.add_theme_stylebox_override("panel", _frame_style(Color("070908"), Color("704421"), 7, 4, 10))
	inspector_module.add_child(socket)
	var portrait := TextureRect.new()
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = INSPECTOR_PORTRAIT_TEXTURE
	portrait.modulate = Color(1.0, 0.90, 0.74, 1.0)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socket.add_child(portrait)
	var mask := TextureRect.new()
	mask.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	mask.texture = INSPECTOR_MASK_TEXTURE
	mask.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mask.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mask.modulate = Color(1.0, 0.55, 0.26, 0.18)
	mask.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socket.add_child(mask)
	var eye_light := Panel.new()
	eye_light.position = Vector2(portrait_size * 0.60, dimensions.y * 0.35)
	eye_light.size = Vector2(11.0, 11.0)
	eye_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eye_light.add_theme_stylebox_override("panel", _lamp_style(true, DANGER))
	socket.add_child(eye_light)
	var title := _label(_t(&"UI_INSPECTOR_OF_COMPLIANCE"), 20 if layout_profile == LayoutProfile.WIDE else 17, Color("efc994"))
	title.position = Vector2(portrait_size + 34.0, 18.0)
	title.size = Vector2(dimensions.x - portrait_size - 54.0, 32.0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	inspector_module.add_child(title)
	enemy_label = _label("", 13 if layout_profile != LayoutProfile.COMPACT else 11, PARCHMENT)
	enemy_label.position = Vector2(portrait_size + 34.0, 50.0)
	enemy_label.size = Vector2(maxf(255.0, dimensions.x - portrait_size - 54.0), dimensions.y - 62.0)
	enemy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_module.add_child(enemy_label)
	inspector_integrity = ProgressBar.new()
	inspector_integrity.position = Vector2(portrait_size + 34.0, dimensions.y - 27.0)
	inspector_integrity.size = Vector2(dimensions.x - portrait_size - 56.0, 10.0)
	inspector_integrity.show_percentage = false
	inspector_integrity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inspector_integrity.add_theme_stylebox_override("background", _frame_style(Color("0b0b0b"), Color("3d2924"), 2, 3, 0))
	inspector_integrity.add_theme_stylebox_override("fill", _frame_style(Color("792e29"), DANGER, 1, 2, 0))
	inspector_module.add_child(inspector_integrity)
	var key_light := Panel.new()
	key_light.position = Vector2(0.0, -16.0)
	key_light.size = Vector2(dimensions.x, 42.0)
	key_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_light.add_theme_stylebox_override("panel", _glow_style(Color(0.92, 0.57, 0.20, 0.16), 36))
	inspector_module.add_child(key_light)


func _add_enemy_row() -> void:
	enemy_row = HBoxContainer.new()
	var y := _inspector_dimensions().y + 18.0
	_place_centered(enemy_row, y, _enemy_row_width(), 62.0)
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	enemy_row.add_theme_constant_override("separation", 14)
	enemy_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_row.z_index = 4
	battle_surface.add_child(enemy_row)
	for index in 3:
		enemy_row.add_child(_unit_slot(_t(&"UI_ENEMY_SLOT", {"index": "%02d" % (index + 1)}), Color("6b342d")))


func _add_ritual_machine() -> void:
	var machine_size := _ritual_size()
	ritual_centerpiece = Panel.new()
	_place_centered(ritual_centerpiece, _ritual_y(), machine_size, machine_size)
	ritual_centerpiece.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ritual_centerpiece.add_theme_stylebox_override("panel", _transparent_style())
	battle_surface.add_child(ritual_centerpiece)
	var disc := Panel.new()
	disc.position = Vector2(0.0, 0.0)
	disc.size = Vector2(machine_size, machine_size)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_theme_stylebox_override("panel", _round_mechanism_style())
	ritual_centerpiece.add_child(disc)
	ritual_emblem_art = TextureRect.new()
	ritual_emblem_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 11)
	ritual_emblem_art.texture = RITUAL_MACHINE_TEXTURE
	ritual_emblem_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ritual_emblem_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ritual_emblem_art.modulate = Color("d39a4b")
	ritual_emblem_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(ritual_emblem_art)
	var seal := TextureRect.new()
	seal.set_anchors_preset(Control.PRESET_CENTER)
	seal.position = Vector2(-machine_size * 0.19, -machine_size * 0.19)
	seal.size = Vector2(machine_size * 0.38, machine_size * 0.38)
	seal.texture = RITUAL_EMBLEM_TEXTURE
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	seal.modulate = Color("efd18b")
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(seal)
	ritual_counter_label = _label("×1\n0", 22 if layout_profile == LayoutProfile.WIDE else 18, Color("ffe0a0"))
	ritual_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ritual_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ritual_counter_label.set_anchors_preset(Control.PRESET_CENTER)
	ritual_counter_label.position = Vector2(-44.0, -28.0)
	ritual_counter_label.size = Vector2(88.0, 56.0)
	ritual_counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(ritual_counter_label)
	for angle in [0.0, 90.0, 180.0, 270.0]:
		var clamp := Panel.new()
		var radius := machine_size * 0.45
		clamp.position = Vector2(machine_size * 0.5 + cos(deg_to_rad(angle)) * radius - 12.0, machine_size * 0.5 + sin(deg_to_rad(angle)) * radius - 12.0)
		clamp.size = Vector2(24.0, 24.0)
		clamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clamp.add_theme_stylebox_override("panel", _frame_style(Color("2a2017"), BRASS_LIGHT, 4, 3, 4))
		disc.add_child(clamp)
	ritual_status_light = Panel.new()
	ritual_status_light.position = Vector2(machine_size - 40.0, 22.0)
	ritual_status_light.size = Vector2(18.0, 18.0)
	ritual_status_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ritual_status_light.add_theme_stylebox_override("panel", _lamp_style(false, AMBER))
	disc.add_child(ritual_status_light)
	machine_feedback = MachineFeedback.new()
	machine_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disc.add_child(machine_feedback)
	var plate := Panel.new()
	machine_plate = plate
	plate.position = Vector2(machine_size - 28.0, machine_size * 0.27)
	plate.size = Vector2(194.0, 76.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel", _frame_style(Color("141311"), Color("66471f"), 7, 3, 9))
	ritual_centerpiece.add_child(plate)
	_add_texture(plate, CINEMATIC_IRON_TEXTURE, 0.28, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	ritual_label = _label("", 13 if layout_profile != LayoutProfile.COMPACT else 11, PARCHMENT)
	ritual_label.position = Vector2(12.0, 8.0)
	ritual_label.size = Vector2(170.0, 30.0)
	ritual_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ritual_label.max_lines_visible = 2
	plate.add_child(ritual_label)
	score_button = _mechanical_button(_t(&"UI_SEAL_RITUAL"), true)
	score_button.position = Vector2(12.0, 43.0)
	score_button.size = Vector2(170.0, 24.0)
	score_button.pressed.connect(func() -> void: score_requested.emit())
	plate.add_child(score_button)
	machine_status = _label("", 11, AMBER)
	machine_status.position = Vector2(12, 73)
	machine_status.size = Vector2(170, 32)
	machine_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	machine_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(machine_status)
	machine_buttons.clear()
	for index in 2:
		var button := _mechanical_button("", false)
		button.position = Vector2(12, 108 + index * 37)
		button.size = Vector2(170, 34)
		button.add_theme_font_size_override("font_size", 11)
		button.pressed.connect(func() -> void:
			if index < machine_options.size():
				machine_mode_requested.emit(machine_options[index]["id"])
		)
		plate.add_child(button)
		machine_buttons.append(button)
	_apply_machine_details()

func render_machine_options(options: Array[Dictionary], status: String, available: bool, charged: bool) -> void:
	machine_options = options
	machine_status_text = status
	machine_available = available
	machine_charged = charged
	_apply_machine_details()

func _apply_machine_details() -> void:
	if machine_plate == null:
		return
	var show_controls := not machine_options.is_empty()
	machine_plate.size.y = 188 if show_controls else 76
	machine_status.visible = show_controls
	machine_status.text = machine_status_text
	machine_status.add_theme_color_override("font_color", DANGER if machine_charged else AMBER)
	for index in machine_buttons.size():
		var button := machine_buttons[index]
		button.visible = index < machine_options.size()
		if button.visible:
			button.text = machine_options[index]["title"]
			button.tooltip_text = machine_options[index]["description"]
			button.add_theme_color_override("font_color", DANGER if machine_options[index].get("lethal", false) else PARCHMENT)
			button.disabled = not machine_available
	machine_feedback.present(machine_available, machine_charged)
	if is_instance_valid(pressure_feedback):
		pressure_feedback.overpressure = machine_available or machine_charged

func show_machine_release(charged: bool) -> void:
	pressure_feedback.burst_age = 0.0
	if not charged:
		machine_feedback.discharge()

func show_machine_discharge() -> void:
	machine_feedback.discharge()


func _add_player_board() -> void:
	player_board_row = HBoxContainer.new()
	_place_centered(player_board_row, _player_row_y(), _player_row_width(), 62.0)
	player_board_row.alignment = BoxContainer.ALIGNMENT_CENTER
	player_board_row.add_theme_constant_override("separation", 14)
	player_board_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_board_row.z_index = 4
	battle_surface.add_child(player_board_row)
	for index in 4:
		player_board_row.add_child(_unit_slot(_t(&"UI_MODULE_BAY", {"index": "%02d" % (index + 1)}), Color("567a78")))


func _add_event_strip() -> void:
	var strip := Panel.new()
	strip.anchor_left = 0.23
	strip.anchor_right = 0.77
	strip.anchor_top = 1.0
	strip.anchor_bottom = 1.0
	strip.offset_bottom = -_hand_height() - 9.0
	strip.offset_top = -_hand_height() - 35.0
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.visible = false
	strip.add_theme_stylebox_override("panel", _frame_style(Color(0.05, 0.05, 0.045, 0.88), Color("513a20"), 3, 3, 4))
	battle_surface.add_child(strip)
	event_label = _label("", 11, Color("c9b58e"))
	event_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	event_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	event_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	event_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	strip.add_child(event_label)


func _add_hand() -> void:
	hand_view = HAND_VIEW_SCENE.instantiate() as HandView
	hand_view.anchor_left = 0.0
	hand_view.anchor_right = 1.0
	hand_view.anchor_bottom = 1.0
	hand_view.offset_left = 24.0
	hand_view.offset_right = -24.0
	hand_view.offset_top = -_hand_height()
	hand_view.offset_bottom = 0.0
	# Only cards receive input; the empty fan bounds must not cover machine levers.
	hand_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_view.play_requested.connect(_on_card_play_requested)
	hand_view.inspect_requested.connect(_on_card_inspect_requested)
	hand_view.preview_requested.connect(func(card: CardData) -> void: preview_requested.emit(card))
	battle_surface.add_child(hand_view)
	var hand_light := Panel.new()
	hand_light.anchor_left = 0.17
	hand_light.anchor_right = 0.83
	hand_light.anchor_top = 1.0
	hand_light.anchor_bottom = 1.0
	hand_light.offset_top = -36.0
	hand_light.offset_bottom = 12.0
	hand_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_light.add_theme_stylebox_override("panel", _glow_style(Color(0.82, 0.48, 0.14, 0.18), 44))
	battle_surface.add_child(hand_light)
	battle_surface.move_child(hand_light, battle_surface.get_child_count() - 2)


func _add_edge_instruments(stage: Control) -> void:
	var rack := Control.new()
	rack.anchor_left = 0.015
	rack.anchor_top = 0.21
	rack.anchor_right = 0.13
	rack.anchor_bottom = 0.81
	rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(rack)
	var vessel_h := 134.0 if layout_profile != LayoutProfile.COMPACT else 110.0
	var vessel_housing := Panel.new()
	vessel_housing.position = Vector2(14.0, 0.0)
	vessel_housing.size = Vector2(52.0, vessel_h + 28.0)
	vessel_housing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vessel_housing.add_theme_stylebox_override("panel", _frame_style(Color("151310"), Color("76512a"), 6, 17, 8))
	rack.add_child(vessel_housing)
	hp_vessel = ProgressBar.new()
	hp_vessel.position = Vector2(12.0, 10.0)
	hp_vessel.size = Vector2(28.0, vessel_h)
	hp_vessel.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	hp_vessel.show_percentage = false
	hp_vessel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_vessel.add_theme_stylebox_override("background", _frame_style(Color("080a09"), Color("5f4a35"), 2, 12, 0))
	hp_vessel.add_theme_stylebox_override("fill", _frame_style(Color("7d2829"), DANGER, 1, 10, 0))
	vessel_housing.add_child(hp_vessel)
	protection_feedback = InstrumentFeedback.new()
	protection_feedback.kind = InstrumentFeedback.Kind.PROTECTION
	protection_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vessel_housing.add_child(protection_feedback)
	player_label = _label("", 11, PARCHMENT)
	player_label.position = Vector2(0.0, vessel_h + 34.0)
	player_label.size = Vector2(100.0, 44.0)
	player_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rack.add_child(player_label)
	var gauge := _build_pressure_gauge()
	gauge.position = Vector2(-8.0, vessel_h + 88.0)
	gauge.size = Vector2(104.0, 92.0)
	rack.add_child(gauge)
	pressure_label = _label("", 11, PARCHMENT)
	pressure_label.position = Vector2(0.0, vessel_h + 182.0)
	pressure_label.size = Vector2(106.0, 34.0)
	pressure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rack.add_child(pressure_label)
	var lamps := HBoxContainer.new()
	lamps.position = Vector2(10.0, vessel_h + 222.0)
	lamps.size = Vector2(82.0, 18.0)
	lamps.alignment = BoxContainer.ALIGNMENT_CENTER
	lamps.add_theme_constant_override("separation", 7)
	for _index in 3:
		var lamp := Panel.new()
		lamp.custom_minimum_size = Vector2(17.0, 17.0)
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lamp.add_theme_stylebox_override("panel", _lamp_style(false, AMBER))
		lamps.add_child(lamp)
		pressure_lamps.append(lamp)
	rack.add_child(lamps)
	doom_label = _label("", 13, TEAL)
	doom_label.position = Vector2(0.0, vessel_h + 254.0)
	doom_label.size = Vector2(112.0, 44.0)
	doom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	doom_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rack.add_child(doom_label)
	weaknesses_label = _label("", 10, Color("c18d72"))
	weaknesses_label.position = Vector2(0.0, vessel_h + 304.0)
	weaknesses_label.size = Vector2(114.0, 58.0)
	weaknesses_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rack.add_child(weaknesses_label)


func _build_pressure_gauge() -> Control:
	var gauge := Control.new()
	var rim := Panel.new()
	rim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rim.add_theme_stylebox_override("panel", _frame_style(Color("151310"), BRASS_LIGHT, 6, 48, 8))
	gauge.add_child(rim)
	var face := TextureRect.new()
	face.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	face.texture = GAUGE_FACE_TEXTURE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_child(face)
	pressure_needle = ColorRect.new()
	pressure_needle.color = AMBER
	pressure_needle.size = Vector2(3.0, 34.0)
	pressure_needle.set_anchors_preset(Control.PRESET_CENTER)
	pressure_needle.position = Vector2(-1.5, -28.0)
	pressure_needle.pivot_offset = Vector2(1.5, 28.0)
	pressure_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.add_child(pressure_needle)
	pressure_feedback = InstrumentFeedback.new()
	pressure_feedback.needle = pressure_needle
	pressure_feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gauge.add_child(pressure_feedback)
	return gauge


func _build_combo_dial() -> Control:
	var dial := Control.new()
	var housing := Panel.new()
	housing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	housing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	housing.add_theme_stylebox_override("panel", _round_mechanism_style())
	dial.add_child(housing)
	var ring := TextureRect.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	ring.texture = RITUAL_MACHINE_TEXTURE
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.modulate = Color("c58a3b")
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dial.add_child(ring)
	combo_dial_label = _label("×1\n0", 16, Color("ffe0a0"))
	combo_dial_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	combo_dial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_dial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	combo_dial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dial.add_child(combo_dial_label)
	return dial


func _add_field_apparatus(stage: Control) -> void:
	var apparatus := Control.new()
	apparatus.anchor_left = 0.83
	apparatus.anchor_right = 0.99
	apparatus.anchor_top = 0.22
	apparatus.anchor_bottom = 0.84
	apparatus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(apparatus)
	var draw_stack := _stack(&"UI_DRAW", true)
	draw_stack.position = Vector2(8.0, 0.0)
	apparatus.add_child(draw_stack)
	var discard_stack := _stack(&"UI_DISCARD", false)
	discard_stack.position = Vector2(8.0, 124.0)
	apparatus.add_child(discard_stack)
	var combo_dial := _build_combo_dial()
	combo_dial.position = Vector2(-10.0, 240.0)
	combo_dial.size = Vector2(112.0, 112.0)
	apparatus.add_child(combo_dial)
	end_turn_button = _round_action_button(_t(&"UI_PROCESS_ENEMY_TURN"))
	end_turn_button.position = Vector2(1.0, 355.0)
	end_turn_button.size = Vector2(132.0, 66.0)
	end_turn_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_turn_button.pressed.connect(func() -> void: end_turn_requested.emit())
	apparatus.add_child(end_turn_button)
	var archive_toggle := _mechanical_button(_t(&"UI_ARCHIVE_FILES_CLOSED"), false)
	archive_toggle.position = Vector2(-4.0, 432.0)
	archive_toggle.size = Vector2(160.0, 28.0)
	archive_toggle.pressed.connect(_toggle_archive.bind(archive_toggle))
	apparatus.add_child(archive_toggle)
	archive_controls = VBoxContainer.new()
	archive_controls.position = Vector2(-154.0, 466.0)
	archive_controls.size = Vector2(314.0, 200.0)
	archive_controls.visible = false
	archive_controls.add_theme_constant_override("separation", 5)
	archive_controls.mouse_filter = Control.MOUSE_FILTER_STOP
	var archive_back := Panel.new()
	archive_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	archive_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	archive_back.add_theme_stylebox_override("panel", _frame_style(Color("10100f"), Color("694821"), 6, 4, 10))
	archive_controls.add_child(archive_back)
	seed_edit = LineEdit.new()
	seed_edit.placeholder_text = _t(&"UI_RUN_SEED")
	seed_edit.custom_minimum_size = Vector2(0.0, 28.0)
	archive_controls.add_child(seed_edit)
	var new_run := _mechanical_button(_t(&"UI_FILE_NEW_RUN"), false)
	new_run.pressed.connect(func() -> void: new_run_requested.emit(seed_edit.text))
	archive_controls.add_child(new_run)
	language_option = OptionButton.new()
	language_option.custom_minimum_size = Vector2(0.0, 28.0)
	language_option.add_item(_t(&"LANGUAGE_ENGLISH"), 0)
	language_option.add_item(_t(&"LANGUAGE_RUSSIAN"), 1)
	language_option.select(0 if LocalizationManager.current_locale == "en" else 1)
	language_option.item_selected.connect(_on_language_selected)
	archive_controls.add_child(language_option)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.custom_minimum_size = Vector2(0.0, 84.0)
	log_label.add_theme_color_override("default_color", Color("c5b28c"))
	archive_controls.add_child(log_label)
	apparatus.add_child(archive_controls)


func _stack(caption_key: StringName, is_draw: bool) -> Control:
	var stack := Control.new()
	stack.size = Vector2(118.0, 110.0)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for offset in [Vector2(12.0, 15.0), Vector2(8.0, 10.0), Vector2(4.0, 5.0)]:
		var back := Panel.new()
		back.position = offset
		back.size = Vector2(72.0, 94.0)
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_theme_stylebox_override("panel", _frame_style(Color("181411"), Color("5e4326"), 4, 4, 5))
		stack.add_child(back)
	var face := TextureRect.new()
	face.position = Vector2(0.0, 0.0)
	face.size = Vector2(72.0, 94.0)
	face.texture = CARD_BACK_TEXTURE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.modulate = Color(0.78, 0.64, 0.46, 1.0) if is_draw else Color(0.36, 0.31, 0.29, 1.0)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(face)
	var label := _label("0\n%s" % _t(caption_key), 11, PARCHMENT)
	label.position = Vector2(77.0, 20.0)
	label.size = Vector2(52.0, 56.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(label)
	if is_draw:
		deck_label = label
	else:
		discard_label = label
	return stack


func _apply_view_state() -> void:
	if current_state == null:
		return
	player_label.text = "%d / %d\n%s %d" % [current_state.player_hp, current_state.max_player_hp, _t(&"UI_BLOCK"), current_state.player_block]
	hp_vessel.value = clampf(float(current_state.player_hp) / maxf(1.0, float(current_state.max_player_hp)) * 100.0, 0.0, 100.0)
	pressure_label.text = "%s\n%d / %d" % [_t(&"UI_PRESSURE"), current_state.energy, current_state.max_energy]
	pressure_feedback.present(current_state.energy, current_state.max_energy, current_state.is_active)
	protection_feedback.present(current_state.player_block, 1, current_state.is_active)
	for index in pressure_lamps.size():
		pressure_lamps[index].add_theme_stylebox_override("panel", _lamp_style(index < current_state.energy, AMBER))
	doom_label.text = "%s\n%d  ×%d" % [_t(&"UI_DOOM_DIAL"), current_state.doom, current_state.multiplier]
	if combo_dial_label != null:
		combo_dial_label.text = "×%d\n%d" % [current_state.multiplier, current_state.doom]
	weaknesses_label.text = "%s\n%s" % [_t(&"UI_VICE_SOCKETS"), current_state.weakness_names]
	enemy_label.text = "%s: %d\n%s: %s" % [_t(&"BATTLE_INTEGRITY"), current_state.enemy_hp, _t(&"BATTLE_INTENT"), _t(&"BATTLE_INTENT_MANDATORY_FEE")]
	inspector_integrity.value = clampf(float(current_state.enemy_hp) / 40.0 * 100.0, 0.0, 100.0)
	var combo_text := current_state.last_combo.get_display_name() if current_state.last_combo.is_match() else _t(&"COMBO_NONE")
	ritual_label.text = "%s: %d +%d\n%s" % [_t(&"UI_COMMITTED"), current_state.played_cards.size(), maxi(0, current_state.played_cards.size() - 1), combo_text]
	ritual_label.tooltip_text = "%s\n%s • %s" % [_t(&"UI_RITUAL_PRESS"), _committed_summary(current_state.played_cards), combo_text]
	deck_label.text = "%d\n%s" % [current_state.draw_count, _t(&"UI_DRAW")]
	discard_label.text = "%d\n%s" % [current_state.discard_count, _t(&"UI_DISCARD")]
	ritual_counter_label.text = "×%d\n%d" % [current_state.multiplier, current_state.doom]
	ritual_status_light.add_theme_stylebox_override("panel", _lamp_style(current_state.can_score, AMBER))
	ritual_emblem_art.modulate = Color("f0c36d") if current_state.can_score else Color("9a7040")
	score_button.disabled = not current_state.can_score
	end_turn_button.disabled = not current_state.is_active
	hand_view.set_hand(current_state.hand, current_state.playable_cards)
	_apply_demo_details()

func render_demo_details(intent_text: String, intent_tooltip: String, max_hp: int, vice_tooltip: String) -> void:
	demo_intent = intent_text
	demo_intent_tooltip = intent_tooltip
	demo_enemy_max_hp = max_hp
	demo_vice_tooltip = vice_tooltip
	_apply_demo_details()

func _apply_demo_details() -> void:
	if demo_intent.is_empty() or current_state == null:
		return
	enemy_label.text = "%s: %d / %d\n%s" % [_t(&"BATTLE_INTEGRITY"), current_state.enemy_hp, demo_enemy_max_hp, demo_intent]
	enemy_label.tooltip_text = demo_intent_tooltip
	inspector_integrity.value = float(current_state.enemy_hp) / maxf(1, demo_enemy_max_hp) * 100.0
	weaknesses_label.tooltip_text = demo_vice_tooltip
	enemy_row.visible = false
	player_board_row.visible = false
	forecast_panel.visible = current_state.is_active
	forecast_label.text = forecast_text
	if not demo_ritual_text.is_empty():
		ritual_label.text = demo_ritual_text
	end_turn_button.tooltip_text = demo_end_turn_tooltip
	_apply_machine_details()

func render_ritual_summary(text: String, turn_tooltip: String) -> void:
	demo_ritual_text = text
	demo_end_turn_tooltip = turn_tooltip
	_apply_demo_details()

func render_forecast(text: String) -> void:
	forecast_text = text
	if forecast_label != null:
		forecast_label.text = text

func _add_forecast_plate() -> void:
	forecast_panel = Panel.new()
	_place_centered(forecast_panel, _ritual_y() + 8.0, 252.0, 196.0)
	forecast_panel.offset_left -= _ritual_size() * 0.5 + 146.0
	forecast_panel.offset_right -= _ritual_size() * 0.5 + 146.0
	forecast_panel.add_theme_stylebox_override("panel", _frame_style(IRON, BRASS, 4, 2, 6))
	forecast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forecast_panel.visible = false
	battle_surface.add_child(forecast_panel)
	_add_texture(forecast_panel, CINEMATIC_IRON_TEXTURE, 0.22, TextureRect.STRETCH_SCALE)
	IronStyleKit.add_frame(forecast_panel, IronStyleKit.FrameLevel.UTILITY)
	forecast_label = _label("", 14, PARCHMENT)
	forecast_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	forecast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	forecast_panel.add_child(forecast_label)


func _render_log() -> void:
	if log_label == null:
		return
	log_label.clear()
	for message in log_entries:
		log_label.append_text("• %s\n" % message.resolve())
	log_label.scroll_to_line(maxi(0, log_label.get_line_count() - 1))
	if event_label != null:
		event_label.text = "" if log_entries.is_empty() else log_entries.back().resolve()


func _on_resized() -> void:
	var next_profile := _layout_profile_for_width(size.x)
	if next_profile != layout_profile:
		layout_profile = next_profile
		_rebuild_presentation()


func _on_locale_changed(_locale: String) -> void:
	# Locale changes are presentation-only, but must be visible in the same frame.
	# Rebuilding here keeps the inspector, archive, buttons, and card copies in one
	# language instead of leaving a frame of mixed EN/RU controls on screen.
	_rebuild_presentation()


func _rebuild_presentation() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	pressure_lamps.clear()
	_build_table()
	set_seed(displayed_seed)
	_apply_view_state()
	_render_log()


func _toggle_archive(button: Button) -> void:
	archive_controls.visible = not archive_controls.visible
	button.text = _t(&"UI_ARCHIVE_FILES_OPEN") if archive_controls.visible else _t(&"UI_ARCHIVE_FILES_CLOSED")


func _on_card_play_requested(card_data: CardData) -> void:
	play_requested.emit(card_data)


func _on_card_inspect_requested(card_data: CardData) -> void:
	inspect_requested.emit(card_data)


func _on_language_selected(index: int) -> void:
	LocalizationManager.set_locale("en" if index == 0 else "ru")


func _animate_presentation_delta(previous_state: BattleTableViewState) -> void:
	if previous_state == null or current_state == null:
		return
	if current_state.enemy_hp < previous_state.enemy_hp:
		_pulse_control(inspector_module, DANGER)
	if current_state.doom != previous_state.doom or current_state.played_cards.size() != previous_state.played_cards.size():
		_pulse_control(ritual_centerpiece, AMBER)
		_rotate_ritual_emblem()
	if current_state.hand.size() != previous_state.hand.size():
		_pulse_control(hand_view, TEAL)
	if current_state.player_hp < previous_state.player_hp:
		_pulse_control(hp_vessel, DANGER)


func _pulse_control(control: Control, accent: Color) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.modulate = accent
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", Color.WHITE, 0.24)
	tween.tween_property(control, "scale", Vector2(1.025, 1.025), 0.10)
	tween.chain().tween_property(control, "scale", Vector2.ONE, 0.16)


func _rotate_ritual_emblem() -> void:
	if ritual_emblem_art == null:
		return
	ritual_emblem_art.pivot_offset = ritual_emblem_art.size * 0.5
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ritual_emblem_art, "rotation", ritual_emblem_art.rotation + deg_to_rad(15.0), 0.26)


func _place_centered(control: Control, top: float, width: float, height: float) -> void:
	control.anchor_left = 0.5
	control.anchor_right = 0.5
	control.anchor_top = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = -width * 0.5
	control.offset_right = width * 0.5
	control.offset_top = top
	control.offset_bottom = top + height


func _add_texture(target: Control, texture: Texture2D, opacity: float, stretch: TextureRect.StretchMode) -> void:
	var overlay := TextureRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.texture = texture
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = stretch
	overlay.modulate = Color(1.0, 1.0, 1.0, opacity)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.add_child(overlay)
	target.move_child(overlay, 0)


func _add_rivets(target: Control, inset: float) -> void:
	for anchor in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0)]:
		var rivet := Panel.new()
		rivet.set_anchors_preset(Control.PRESET_TOP_LEFT)
		rivet.position = Vector2(inset, inset)
		if anchor.x > 0.5:
			rivet.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			rivet.position = Vector2(-inset - 8.0, inset)
		if anchor.y > 0.5:
			rivet.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if anchor.x < 0.5 else Control.PRESET_BOTTOM_RIGHT)
			rivet.position = Vector2(inset if anchor.x < 0.5 else -inset - 8.0, -inset - 8.0)
		rivet.size = Vector2(8.0, 8.0)
		rivet.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rivet.add_theme_stylebox_override("panel", _lamp_style(false, BRASS_LIGHT))
		target.add_child(rivet)


func _slot(caption: String, fill: Color, border: Color, slot_size: Vector2) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = slot_size
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel", _frame_style(fill, border, 5, 4, 6))
	var label := _label(caption, 9, Color("9e9076"))
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slot.add_child(label)
	return slot


func _unit_slot(caption: String, accent: Color) -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(58.0, 62.0)
	slot.tooltip_text = caption
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel", _frame_style(Color("100f0d"), accent, 4, 3, 7))
	var back := TextureRect.new()
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 5)
	back.texture = CARD_BACK_TEXTURE
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back.modulate = Color(0.60, 0.42, 0.25, 0.90)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(back)
	return slot


func _mechanical_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("f0dbad") if primary else Color("b9aa8a"))
	button.add_theme_stylebox_override("normal", _frame_style(Color("392717") if primary else Color("191917"), BRASS if primary else Color("514532"), 6 if primary else 3, 3, 5))
	button.add_theme_stylebox_override("hover", _frame_style(Color("4d3720"), TEAL, 6 if primary else 3, 3, 5))
	button.add_theme_stylebox_override("pressed", _frame_style(Color("21160f"), TEAL, 6 if primary else 3, 3, 3))
	button.add_theme_stylebox_override("disabled", _frame_style(Color("171614"), Color("3d3932"), 4, 3, 0))
	return button


func _round_action_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color("f0dbad"))
	button.add_theme_stylebox_override("normal", _frame_style(Color("332313"), BRASS_LIGHT, 7, 36, 12))
	button.add_theme_stylebox_override("hover", _frame_style(Color("4d3720"), TEAL, 7, 36, 12))
	button.add_theme_stylebox_override("pressed", _frame_style(Color("21160f"), TEAL, 7, 36, 7))
	button.add_theme_stylebox_override("disabled", _frame_style(Color("171614"), Color("3d3932"), 5, 36, 0))
	return button


func _frame_style(fill: Color, border: Color, border_width: int, radius: int, shadow_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(2.0, 5.0)
	return style


func _glow_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = color
	style.shadow_size = radius / 3
	return style


func _round_mechanism_style() -> StyleBoxFlat:
	var style := _frame_style(Color("13120f"), BRASS_LIGHT, 12, _ritual_size() / 2, 18)
	style.border_width_top = 14
	style.border_width_bottom = 14
	return style


func _transparent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	return style


func _lamp_style(active: bool, accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent if active else Color("24221d")
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("ffe0a0") if active else Color("705536")
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	style.shadow_color = Color(accent, 0.55) if active else Color(0.0, 0.0, 0.0, 0.40)
	style.shadow_size = 6 if active else 2
	return style


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_presentation_theme() -> Theme:
	var presentation_theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Noto Sans", "Arial"])
	presentation_theme.default_font = font
	presentation_theme.default_font_size = 14
	return presentation_theme


func _layout_profile_for_width(width: float) -> LayoutProfile:
	if width >= 1750.0:
		return LayoutProfile.WIDE
	if width >= 1480.0:
		return LayoutProfile.STANDARD
	return LayoutProfile.COMPACT


func _inspector_dimensions() -> Vector2:
	match layout_profile:
		LayoutProfile.WIDE:
			return Vector2(760.0, 188.0)
		LayoutProfile.STANDARD:
			return Vector2(670.0, 160.0)
		_:
			return Vector2(550.0, 134.0)


func _portrait_size() -> float:
	match layout_profile:
		LayoutProfile.WIDE:
			return 178.0
		LayoutProfile.STANDARD:
			return 146.0
		_:
			return 118.0


func _ritual_size() -> float:
	match layout_profile:
		LayoutProfile.WIDE:
			return 322.0
		LayoutProfile.STANDARD:
			return 276.0
		_:
			return 204.0


func _ritual_y() -> float:
	match layout_profile:
		LayoutProfile.WIDE:
			return 245.0
		LayoutProfile.STANDARD:
			return 205.0
		_:
			return 168.0


func _player_row_y() -> float:
	match layout_profile:
		LayoutProfile.WIDE:
			return 576.0
		LayoutProfile.STANDARD:
			return 502.0
		_:
			return 352.0


func _hand_height() -> float:
	return CardView.CARD_SIZE.y + (34.0 if layout_profile == LayoutProfile.WIDE else 24.0)


func _slot_width() -> float:
	return 130.0 if layout_profile == LayoutProfile.WIDE else 112.0 if layout_profile == LayoutProfile.STANDARD else 94.0


func _enemy_row_width() -> float:
	return _slot_width() * 3.0 + 36.0


func _player_row_width() -> float:
	return _slot_width() * 4.0 + 54.0


func _t(key: StringName, arguments: Dictionary = {}) -> String:
	return LocalizationManager.translate(key, arguments)


func _committed_summary(cards: Array[CardData]) -> String:
	if cards.is_empty():
		return _t(&"UI_NO_FILES")
	var first_title := cards[0].get_title()
	return first_title if cards.size() == 1 else "%s +%d" % [first_title, cards.size() - 1]
